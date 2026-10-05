import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// 0..1 loudness for the mic icon; dictation levels scale to the range seen.
class SoundLevel extends ValueNotifier<double> {
  SoundLevel() : super(0);

  double? _min;
  double? _max;

  void reset() {
    _min = null;
    _max = null;
    value = 0;
  }

  /// A raw level from speech_to_text (any scale).
  void addRaw(double level) {
    _min = math.min(_min ?? level, level);
    _max = math.max(_max ?? level, level);
    final range = _max! - _min!;
    value = range < 1e-6 ? 0 : ((level - _min!) / range).clamp(0.0, 1.0);
  }

  /// 16-bit little-endian mono PCM; -55 dBFS and below is silence.
  void addPcm16(Uint8List chunk) {
    final samples = chunk.length ~/ 2;
    if (samples == 0) return;
    final data = ByteData.sublistView(chunk);
    var sum = 0.0;
    for (var i = 0; i < samples; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768;
      sum += s * s;
    }
    final rms = math.sqrt(sum / samples);
    final db = rms <= 0 ? -100.0 : 20 * math.log(rms) / math.ln10;
    value = ((db + 55) / 45).clamp(0.0, 1.0);
  }
}
