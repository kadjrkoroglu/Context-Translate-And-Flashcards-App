import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:translate_app/data/ocr/ocr_core.dart';

/// A recognized line: corners TL, TR, BR, BL in image pixels.
class LineBox {
  final List<Offset> corners;
  final LabelColors colors;

  const LineBox(this.corners, this.colors);

  Offset get _along => corners[1] - corners[0];
  Offset get _across => corners[3] - corners[0];
  double get width => _along.distance;
  double get height => _across.distance;
  double get angle => math.atan2(_along.dy, _along.dx);
  Offset get _u => _along / math.max(width, 1e-6);
  Offset get _v => _across / math.max(height, 1e-6);
}

// Strict on purpose: lines that don't clearly belong together stay apart,
// and the AI still decides whether a group is one text or separate entries.
const double _maxAngleDiff = 0.09; // ~5 degrees
const double _maxHeightRatio = 1.35;
const double _maxGap = 0.9; // in line heights
const double _minOverlap = 0.4; // of the narrower line
const double _maxColorDistance = 90; // RGB distance, out of ~441

double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

double _colorDistance(int a, int b) {
  double channel(int c, int shift) => ((c >> shift) & 0xFF).toDouble();
  final dr = channel(a, 16) - channel(b, 16);
  final dg = channel(a, 8) - channel(b, 8);
  final db = channel(a, 0) - channel(b, 0);
  return math.sqrt(dr * dr + dg * dg + db * db);
}

/// The gap from [upper]'s bottom to [lower]'s top, in [upper]'s frame, if
/// [lower] reads as the next line of the same paragraph; null otherwise.
double? _nextLineGap(LineBox upper, LineBox lower) {
  if ((upper.angle - lower.angle).abs() > _maxAngleDiff) return null;
  final ratio =
      math.max(upper.height, lower.height) /
      math.max(math.min(upper.height, lower.height), 1e-6);
  if (ratio > _maxHeightRatio) return null;

  final h = (upper.height + lower.height) / 2;
  final top = _dot(lower.corners[0] - upper.corners[0], upper._v);
  final gap = top - upper.height;
  if (gap < -0.3 * h || gap > _maxGap * h) return null;

  final start = _dot(lower.corners[0] - upper.corners[0], upper._u);
  final end = _dot(lower.corners[1] - upper.corners[0], upper._u);
  final overlap = math.min(upper.width, end) - math.max(0.0, start);
  if (overlap < _minOverlap * math.min(upper.width, lower.width)) return null;

  if (_colorDistance(upper.colors.background, lower.colors.background) >
          _maxColorDistance ||
      _colorDistance(upper.colors.foreground, lower.colors.foreground) >
          _maxColorDistance) {
    return null;
  }
  return gap;
}

/// Lines that sit together like the lines of one paragraph (same column,
/// size, angle and colors, one right under the other), as index groups in
/// reading order. Side-by-side columns don't mix.
List<List<int>> groupLines(List<LineBox> lines) {
  // Each line links to the closest line right below it, one link each way.
  final below = List<int?>.filled(lines.length, null);
  final above = List<int?>.filled(lines.length, null);
  final pairs = <(double, int, int)>[
    for (var a = 0; a < lines.length; a++)
      for (var b = 0; b < lines.length; b++)
        if (a != b)
          if (_nextLineGap(lines[a], lines[b]) case final gap?) (gap, a, b),
  ]..sort((x, y) => x.$1.compareTo(y.$1));
  for (final (_, a, b) in pairs) {
    if (below[a] == null && above[b] == null) {
      below[a] = b;
      above[b] = a;
    }
  }

  final groups = <List<int>>[
    for (var i = 0; i < lines.length; i++)
      if (above[i] == null) [for (int? j = i; j != null; j = below[j]) j],
  ];
  // Reading order of the input decides the order of the groups.
  return groups..sort((a, b) => a.first.compareTo(b.first));
}

/// One box around all [lines], in the first line's direction.
List<Offset> enclosingCorners(List<LineBox> lines) {
  final first = lines.first;
  final origin = first.corners[0];
  var minU = double.infinity, maxU = -double.infinity;
  var minV = double.infinity, maxV = -double.infinity;
  for (final line in lines) {
    for (final c in line.corners) {
      final u = _dot(c - origin, first._u);
      final v = _dot(c - origin, first._v);
      minU = math.min(minU, u);
      maxU = math.max(maxU, u);
      minV = math.min(minV, v);
      maxV = math.max(maxV, v);
    }
  }
  Offset at(double u, double v) => origin + first._u * u + first._v * v;
  return [at(minU, minV), at(maxU, minV), at(maxU, maxV), at(minU, maxV)];
}
