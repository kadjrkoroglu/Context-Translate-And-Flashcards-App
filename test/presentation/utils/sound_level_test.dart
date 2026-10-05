import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/presentation/utils/sound_level.dart';

Uint8List pcm(int amplitude, {int samples = 1600}) {
  final data = ByteData(samples * 2);
  for (var i = 0; i < samples; i++) {
    data.setInt16(i * 2, i.isEven ? amplitude : -amplitude, Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  test('dictation levels are scaled to the range heard so far', () {
    final level = SoundLevel();

    level.addRaw(-40);
    expect(level.value, 0);
    level.addRaw(-10);
    expect(level.value, 1);
    level.addRaw(-25);
    expect(level.value, closeTo(0.5, 0.001));

    level.reset();
    expect(level.value, 0);
    level.addRaw(5);
    expect(level.value, 0);
  });

  test('Live audio: silence is 0, a loud voice is near 1', () {
    final level = SoundLevel();

    level.addPcm16(pcm(0));
    expect(level.value, 0);
    level.addPcm16(pcm(30));
    expect(level.value, 0);
    level.addPcm16(pcm(1000));
    expect(level.value, inInclusiveRange(0.3, 0.7));
    level.addPcm16(pcm(25000));
    expect(level.value, greaterThan(0.95));
  });
}
