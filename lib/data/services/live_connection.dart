import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/domain/entities/live_session_grant.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

sealed class LiveEvent {
  const LiveEvent();
}

class LiveHeard extends LiveEvent {
  final String text;
  const LiveHeard(this.text);
}

class LiveTranslated extends LiveEvent {
  final String text;
  const LiveTranslated(this.text);
}

/// 16-bit PCM, 24 kHz, mono.
class LiveAudio extends LiveEvent {
  final Uint8List pcm;
  const LiveAudio(this.pcm);
}

class LiveTurnComplete extends LiveEvent {
  const LiveTurnComplete();
}

class LiveGoAway extends LiveEvent {
  const LiveGoAway();
}

class LiveClosed extends LiveEvent {
  final String? reason;
  const LiveClosed(this.reason);
}

/// Gemini Live WebSocket, opened with the backend's ephemeral token.
class LiveConnection {
  static const String _endpoint =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage'
      '.v1beta.GenerativeService.BidiGenerateContentConstrained';
  static const Duration _setupTimeout = Duration(seconds: 10);

  final WebSocketChannel _channel;
  final StreamController<LiveEvent> _events = StreamController<LiveEvent>();
  final Completer<void> _ready = Completer<void>();
  bool _closed = false;

  LiveConnection._(this._channel);

  Stream<LiveEvent> get events => _events.stream;

  static Future<LiveConnection> connect(LiveSessionGrant grant) async {
    final channel = WebSocketChannel.connect(
      Uri.parse('$_endpoint?access_token=${grant.token}'),
    );
    final connection = LiveConnection._(channel);
    try {
      await channel.ready.timeout(_setupTimeout);
      connection._listen();
      channel.sink.add(jsonEncode({'setup': grant.setup}));
      await connection._ready.future.timeout(_setupTimeout);
      return connection;
    } on SocketException catch (e) {
      connection.close();
      throw NetworkException('No internet connection', details: '$e');
    } on TimeoutException {
      connection.close();
      throw const NetworkException('Live connection timed out');
    } catch (e) {
      connection.close();
      if (e is AppException) rethrow;
      throw GeneralException('Live connection failed', details: '$e');
    }
  }

  void _listen() {
    _channel.stream.listen(
      _onMessage,
      onError: (Object e) => _finish('$e'),
      onDone: () => _finish(_channel.closeReason),
    );
  }

  void _finish(String? reason) {
    _closed = true;
    if (!_ready.isCompleted) {
      _ready.completeError(
        GeneralException('Live connection closed', details: reason),
      );
    }
    if (!_events.isClosed) {
      _events.add(LiveClosed(reason));
      _events.close();
    }
  }

  void _onMessage(dynamic data) {
    final Map<String, dynamic> json;
    try {
      // Gemini sends its JSON in binary frames.
      final text = data is String ? data : utf8.decode(data as List<int>);
      json = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    if (json.containsKey('setupComplete')) {
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    if (json.containsKey('goAway')) {
      _events.add(const LiveGoAway());
      return;
    }

    final content = json['serverContent'];
    if (content is! Map) return;

    final input = content['inputTranscription'];
    final heard = input is Map ? input['text'] : null;
    if (heard is String && heard.isNotEmpty) _events.add(LiveHeard(heard));

    final output = content['outputTranscription'];
    final translated = output is Map ? output['text'] : null;
    if (translated is String && translated.isNotEmpty) {
      _events.add(LiveTranslated(translated));
    }

    final turn = content['modelTurn'];
    final parts = turn is Map ? turn['parts'] : null;
    if (parts is List) {
      for (final part in parts) {
        if (part is! Map) continue;
        final inline = part['inlineData'];
        final audio = inline is Map ? inline['data'] : null;
        if (audio is String) _events.add(LiveAudio(base64Decode(audio)));
      }
    }

    if (content['turnComplete'] == true) _events.add(const LiveTurnComplete());
  }

  void sendAudio(Uint8List pcm) {
    if (_closed) return;
    _channel.sink.add(
      jsonEncode({
        'realtimeInput': {
          'audio': {
            'data': base64Encode(pcm),
            'mimeType': 'audio/pcm;rate=16000',
          },
        },
      }),
    );
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _channel.sink.close(status.normalClosure).ignore();
  }
}
