import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:record/record.dart' hide IosAudioCategory;

/// Mic in (16 kHz PCM) and speaker out (24 kHz PCM).
class LiveAudioService {
  static const int _captureRate = 16000;
  static const int _playbackRate = 24000;
  // Gemini wants ~100 ms chunks.
  static const int _chunkBytes = _captureRate * 2 ~/ 10;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSubscription;
  final BytesBuilder _pending = BytesBuilder(copy: false);
  bool _playerReady = false;

  Future<bool> hasMicPermission() => _recorder.hasPermission();

  /// Speaker first: iOS must allow play and record before the mic starts.
  Future<void> startCapture(void Function(Uint8List chunk) onChunk) async {
    await _setupPlayer();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _captureRate,
        numChannels: 1,
        // Keep the translation out of the mic.
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _pending.clear();
    _micSubscription = stream.listen((data) {
      _pending.add(data);
      while (_pending.length >= _chunkBytes) {
        final all = _pending.takeBytes();
        onChunk(Uint8List.sublistView(all, 0, _chunkBytes));
        if (all.length > _chunkBytes) {
          _pending.add(Uint8List.sublistView(all, _chunkBytes));
        }
      }
    });
  }

  Future<void> _setupPlayer() async {
    if (_playerReady) return;
    await FlutterPcmSound.setup(
      sampleRate: _playbackRate,
      channelCount: 1,
      iosAudioCategory: IosAudioCategory.playAndRecord,
    );
    _playerReady = true;
  }

  Future<void> play(Uint8List pcm) async {
    if (!_playerReady || pcm.length < 2) return;
    // A copy: the plugin sends the whole underlying buffer.
    final even = Uint8List.fromList(
      pcm.length.isEven ? pcm : pcm.sublist(0, pcm.length - 1),
    );
    await FlutterPcmSound.feed(PcmArrayInt16(bytes: even.buffer.asByteData()));
  }

  Future<void> stop() async {
    await _micSubscription?.cancel();
    _micSubscription = null;
    _pending.clear();
    if (await _recorder.isRecording()) await _recorder.stop();
    if (_playerReady) {
      _playerReady = false;
      await FlutterPcmSound.release();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}
