import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/data/ocr/line_grouping.dart';
import 'package:translate_app/data/ocr/ocr_core.dart';

const dark = LabelColors(0xFFFFFFFF, 0xFF111111);
const sign = LabelColors(0xFFD32F2F, 0xFFFFFFFF);

/// A line box at ([x], [y]), optionally turned by [degrees] around (0, 0).
LineBox line(
  double x,
  double y,
  double width, {
  double height = 20,
  LabelColors colors = dark,
  double degrees = 0,
}) {
  final a = degrees * math.pi / 180;
  Offset turn(double px, double py) => Offset(
    px * math.cos(a) - py * math.sin(a),
    px * math.sin(a) + py * math.cos(a),
  );
  return LineBox([
    turn(x, y),
    turn(x + width, y),
    turn(x + width, y + height),
    turn(x, y + height),
  ], colors);
}

void main() {
  test('a sentence broken over two lines is one group', () {
    expect(groupLines([line(10, 10, 60), line(10, 36, 110)]), [
      [0, 1],
    ]);
  });

  test('two columns stay apart even when their rows interleave', () {
    final groups = groupLines([
      line(10, 10, 150),
      line(300, 12, 150),
      line(10, 36, 140),
      line(300, 38, 150),
    ]);
    expect(groups, [
      [0, 2],
      [1, 3],
    ]);
  });

  test('a heading is not joined to the text under it', () {
    expect(groupLines([line(10, 10, 200, height: 40), line(10, 56, 200)]), [
      [0],
      [1],
    ]);
  });

  test('lines far apart are separate', () {
    expect(groupLines([line(10, 10, 100), line(10, 90, 100)]), [
      [0],
      [1],
    ]);
  });

  test('text in other colors is separate', () {
    expect(groupLines([line(10, 10, 100), line(10, 36, 100, colors: sign)]), [
      [0],
      [1],
    ]);
  });

  test('a name and its price on the same row are separate', () {
    expect(groupLines([line(10, 10, 140), line(260, 10, 50)]), [
      [0],
      [1],
    ]);
  });

  test('a turned paragraph still groups', () {
    expect(
      groupLines([
        line(10, 10, 120, degrees: 12),
        line(10, 36, 100, degrees: 12),
      ]),
      [
        [0, 1],
      ],
    );
  });

  test('a long list of lines is one chain, in order', () {
    expect(
      groupLines([for (var i = 0; i < 4; i++) line(10, 10 + i * 26, 120)]),
      [
        [0, 1, 2, 3],
      ],
    );
  });

  test('the joined box covers every line', () {
    final box = enclosingCorners([line(10, 10, 60), line(10, 36, 110)]);
    expect(box[0], const Offset(10, 10));
    expect(box[1], const Offset(120, 10));
    expect(box[2], const Offset(120, 56));
    expect(box[3], const Offset(10, 56));
  });
}
