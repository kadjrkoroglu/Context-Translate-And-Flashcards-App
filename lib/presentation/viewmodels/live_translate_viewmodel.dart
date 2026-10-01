import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/constants/ml_languages.dart';
import 'package:translate_app/data/services/live_audio_service.dart';
import 'package:translate_app/data/services/live_connection.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/domain/entities/live_entry.dart';
import 'package:translate_app/domain/entities/live_session_grant.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';

enum LiveStatus { idle, connecting, listening, error }

/// One-way Live translation. Time comes in slices (up to 10 min); the
/// connection is swapped before a slice ends.
class LiveTranslateViewModel extends ChangeNotifier {
  static const int _renewBeforeSeconds = 20;
  static const Duration _retryDelay = Duration(seconds: 5);
  static const int _entryLengthSoftCap = 200;
  static final RegExp _sentenceEnd = RegExp(r'[.!?。！？]\s*$');

  final TranslateUsecase _usecase;
  final LiveAudioService _audio;
  final SettingsService _settings;
  final VoidCallback? _onSessionEnded;

  LiveTranslateViewModel(
    this._usecase,
    this._audio,
    this._settings, {
    VoidCallback? onSessionEnded,
  }) : _onSessionEnded = onSessionEnded,
       _targetLanguage = _settings.liveTargetLang ?? _defaultTarget(_settings);

  // '-' means no AI target chosen yet.
  static String _defaultTarget(SettingsService settings) {
    final target = settings.geminiTargetLang;
    return target == '-' ? 'English' : target;
  }

  String _targetLanguage;

  LiveStatus _status = LiveStatus.idle;
  AppException? _exception;
  final List<LiveEntry> _entries = [];
  bool _speakerOn = true;

  LiveConnection? _connection;
  StreamSubscription<LiveEvent>? _subscription;
  String? _sessionId;
  Timer? _ticker;
  DateTime _sliceStart = DateTime.now();
  int _sliceGranted = 0;
  int _remainingAfterGrant = 0;
  int? _lastKnownRemaining;
  bool _renewing = false;
  DateTime? _nextRetry;
  AppException? _stopAtSliceEnd;
  bool _disposed = false;

  String get targetLanguage => _targetLanguage;
  List<String> get recentLanguages => _settings.recentLanguages;
  LiveStatus get status => _status;
  AppException? get exception => _exception;
  List<LiveEntry> get entries => List.unmodifiable(_entries);
  bool get speakerOn => _speakerOn;
  bool get isActive =>
      _status == LiveStatus.connecting || _status == LiveStatus.listening;

  int? get remainingSeconds {
    if (!isActive || _sliceGranted == 0) return _lastKnownRemaining;
    final elapsed = DateTime.now().difference(_sliceStart).inSeconds;
    return math.max(0, _remainingAfterGrant + _sliceGranted - elapsed);
  }

  static String languageCodeFor(String language) {
    switch (language) {
      case 'Persian':
        return 'fa';
      case 'Urdu':
        return 'ur';
      default:
        return MlLanguages.mapNameToBCP(language);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String get _languageCode => languageCodeFor(_targetLanguage);

  /// Locked while a session runs (the language is in its token).
  void setTargetLanguage(String language) {
    if (isActive || language == _targetLanguage) return;
    _targetLanguage = language;
    _settings.setLiveTargetLang(language);
    _settings.addRecentLanguage(language);
    _notify();
  }

  Future<void> start() async {
    if (isActive) return;
    _exception = null;
    _stopAtSliceEnd = null;
    _status = LiveStatus.connecting;
    _notify();

    try {
      if (!await _audio.hasMicPermission()) {
        throw const MicrophoneDeniedException('Microphone access is off');
      }
      final grant = await _usecase.startLiveSession(_languageCode);
      final connection = await _connect(grant);
      if (_disposed) {
        connection.close();
        await _giveBack(grant.sessionId);
        return;
      }
      _adopt(connection, grant);
      await _audio.startCapture(_onMicChunk);
      _status = LiveStatus.listening;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _notify();
    } catch (e) {
      await _fail(
        e is AppException ? e : GeneralException('Live failed', details: '$e'),
      );
    }
  }

  /// Refunds the reserved time if connecting fails.
  Future<LiveConnection> _connect(LiveSessionGrant grant) async {
    try {
      return await LiveConnection.connect(grant);
    } catch (_) {
      await _giveBack(grant.sessionId);
      rethrow;
    }
  }

  /// Awaited so the next remaining-time read includes the refund.
  Future<void> _giveBack(String sessionId) async {
    try {
      _lastKnownRemaining = await _usecase
          .endLiveSession(sessionId)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline: the time stays charged.
    }
  }

  void _adopt(LiveConnection connection, LiveSessionGrant grant) {
    _connection = connection;
    _sessionId = grant.sessionId;
    _sliceStart = DateTime.now();
    _sliceGranted = grant.grantedSeconds;
    _remainingAfterGrant = grant.remainingSeconds;
    _subscription = connection.events.listen(
      (event) => _onEvent(connection, event),
    );
  }

  void _onMicChunk(Uint8List chunk) => _connection?.sendAudio(chunk);

  void _onEvent(LiveConnection source, LiveEvent event) {
    // Stale event from a swapped-out connection.
    if (!identical(source, _connection)) return;
    switch (event) {
      case LiveHeard(:final text):
        _current().heard += text;
      case LiveTranslated(:final text):
        final entry = _current();
        entry.translated += text;
        if (entry.translated.length > _entryLengthSoftCap &&
            _sentenceEnd.hasMatch(entry.translated)) {
          entry.done = true;
        }
      case LiveAudio(:final pcm):
        if (_speakerOn) _audio.play(pcm).ignore();
      case LiveTurnComplete():
        if (_entries.isNotEmpty) _entries.last.done = true;
      case LiveGoAway():
        _renew();
      case LiveClosed():
        // Dropped on its own: take a new one if time is left.
        if (isActive) _renew(connectionLost: true);
    }
    _notify();
  }

  LiveEntry _current() {
    if (_entries.isEmpty || _entries.last.done) _entries.add(LiveEntry());
    return _entries.last;
  }

  void _tick() {
    if (!isActive) return;
    final elapsed = DateTime.now().difference(_sliceStart).inSeconds;
    if (elapsed >= _sliceGranted) {
      _fail(
        _stopAtSliceEnd ??
            const NetworkException('Live translation lost its connection'),
      );
      return;
    }
    if (elapsed >= _sliceGranted - _renewBeforeSeconds) _renew();
    _notify();
  }

  Future<void> _renew({bool connectionLost = false}) async {
    final retryAt = _nextRetry;
    if (_renewing ||
        _stopAtSliceEnd != null ||
        (retryAt != null && DateTime.now().isBefore(retryAt))) {
      return;
    }
    _renewing = true;
    try {
      final grant = await _usecase.startLiveSession(_languageCode);
      final connection = await _connect(grant);
      if (!isActive) {
        connection.close();
        await _giveBack(grant.sessionId);
        return;
      }

      final oldConnection = _connection;
      final oldSession = _sessionId;
      await _subscription?.cancel();
      _adopt(connection, grant);
      oldConnection?.close();
      if (oldSession != null) _usecase.endLiveSession(oldSession).ignore();
      _nextRetry = null;
    } on QuotaExceededException catch (e) {
      // Quota used up: a live connection plays out its slice, a dead one stops.
      _stopAtSliceEnd = e;
      if (connectionLost) await _fail(e);
    } catch (_) {
      _nextRetry = DateTime.now().add(_retryDelay);
    } finally {
      _renewing = false;
      _notify();
    }
  }

  Future<void> stop() async {
    if (!isActive) return;
    _status = LiveStatus.idle;
    await _teardown();
    _notify();
  }

  Future<void> _fail(AppException exception) async {
    await _teardown();
    _status = LiveStatus.error;
    _exception = exception;
    _notify();
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _subscription?.cancel();
    _subscription = null;
    _connection?.close();
    _connection = null;
    await _audio.stop().catchError((_) {});

    final session = _sessionId;
    _sessionId = null;
    _sliceGranted = 0;
    _nextRetry = null;
    if (session != null) await _giveBack(session);
    _onSessionEnded?.call();
  }

  void toggleSpeaker() {
    _speakerOn = !_speakerOn;
    _notify();
  }

  void clear() {
    _entries.clear();
    _notify();
  }

  void clearError() {
    _exception = null;
    if (_status == LiveStatus.error) _status = LiveStatus.idle;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    if (isActive) {
      _teardown();
    }
    _audio.dispose().catchError((_) {});
    super.dispose();
  }
}
