// PaddleOCR PP-OCRv5 pre/post-processing in pure Dart (same on iOS and
// Android, isolate-safe). Mirrors DetResizeForTest, DBPostProcess,
// get_rotate_crop_image, RecResizeImg and CTCLabelDecode.
import 'dart:math' as math;
import 'dart:typed_data';

/// Decoded photo pixels (RGBA, row-major), already upright.
class RgbaImage {
  final Uint8List pixels;
  final int width;
  final int height;

  const RgbaImage(this.pixels, this.width, this.height);
}

/// Line corners in reading order (TL, TR, BR, BL), in image pixels.
class TextQuad {
  final List<math.Point<double>> corners;

  const TextQuad(this.corners);

  double get width => corners[0].distanceTo(corners[1]);
  double get height => corners[0].distanceTo(corners[3]);
}

class DetInput {
  final Float32List data;
  final int width;
  final int height;

  const DetInput(this.data, this.width, this.height);
}

class RecBatch {
  /// NCHW, BGR, normalized to [-1, 1], zero padded on the right.
  final Float32List data;
  final int width;

  /// Indexes into the quad list, one per batch item.
  final List<int> quadIndexes;

  const RecBatch(this.data, this.width, this.quadIndexes);
}

class RecognizedText {
  final String text;
  final double confidence;

  const RecognizedText(this.text, this.confidence);
}

const int _detLongSide = 960;
const List<double> _detMean = [0.485, 0.456, 0.406];
const List<double> _detStd = [0.229, 0.224, 0.225];

/// Long side 960, sides rounded to multiples of 32, BGR normalized.
DetInput buildDetInput(RgbaImage image) {
  final ratio = _detLongSide / math.max(image.width, image.height);
  // Round half to even, like PaddleOCR's Python round().
  int roundHalfEven(double v) {
    final floor = v.floorToDouble();
    final diff = v - floor;
    if (diff != 0.5) return v.round();
    return floor.toInt().isEven ? floor.toInt() : floor.toInt() + 1;
  }

  int round32(double v) => math.max(32, roundHalfEven(v / 32) * 32);
  final w = round32(image.width * ratio);
  final h = round32(image.height * ratio);
  final plane = w * h;
  final data = Float32List(3 * plane);
  final sx = image.width / w;
  final sy = image.height / h;
  final rgb = Float64List(3);

  for (var y = 0; y < h; y++) {
    final fy = (y + 0.5) * sy - 0.5;
    for (var x = 0; x < w; x++) {
      _sampleBilinear(image, (x + 0.5) * sx - 0.5, fy, rgb);
      final i = y * w + x;
      data[i] = (rgb[2] / 255 - _detMean[0]) / _detStd[0];
      data[plane + i] = (rgb[1] / 255 - _detMean[1]) / _detStd[1];
      data[2 * plane + i] = (rgb[0] / 255 - _detMean[2]) / _detStd[2];
    }
  }
  return DetInput(data, w, h);
}

const double _binaryThresh = 0.3;
const double _boxThresh = 0.6;
const double _unclipRatio = 1.5;
const int _minSide = 3;

/// Probability map → line quads in image pixels, in reading order.
List<TextQuad> findTextQuads(
  Float32List prob,
  int mapWidth,
  int mapHeight,
  int imageWidth,
  int imageHeight,
) {
  final w = mapWidth;
  final h = mapHeight;
  final visited = Uint8List(w * h);
  final stack = Int32List(w * h);
  final quads = <TextQuad>[];
  final scaleX = imageWidth / w;
  final scaleY = imageHeight / h;

  for (var start = 0; start < w * h; start++) {
    if (visited[start] != 0 || prob[start] <= _binaryThresh) continue;

    // 8-connected component; keep only its edge pixels for the hull.
    final edgeX = <int>[];
    final edgeY = <int>[];
    var top = 0;
    stack[top++] = start;
    visited[start] = 1;
    while (top > 0) {
      final p = stack[--top];
      final px = p % w;
      final py = p ~/ w;
      var isEdge = false;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final nx = px + dx;
          final ny = py + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) {
            isEdge = true;
            continue;
          }
          final n = ny * w + nx;
          if (prob[n] <= _binaryThresh) {
            if (dx == 0 || dy == 0) isEdge = true;
            continue;
          }
          if (visited[n] == 0) {
            visited[n] = 1;
            stack[top++] = n;
          }
        }
      }
      if (isEdge) {
        edgeX.add(px);
        edgeY.add(py);
      }
    }

    final rect = _minAreaRect(edgeX, edgeY);
    if (rect == null || math.min(rect.w, rect.h) < _minSide) continue;
    if (_meanProbInside(prob, w, h, rect) < _boxThresh) continue;

    // Grow the shrunk text kernel back to the full text size.
    final d = rect.w * rect.h * _unclipRatio / (2 * (rect.w + rect.h));
    final grown = _Rect(
      rect.cx,
      rect.cy,
      rect.ex,
      rect.ey,
      rect.w + 2 * d,
      rect.h + 2 * d,
    );
    if (math.min(grown.w, grown.h) < _minSide + 2) continue;

    quads.add(_toReadingQuad(grown, scaleX, scaleY, imageWidth, imageHeight));
  }
  return _sortReadingOrder(quads);
}

class _Rect {
  final double cx;
  final double cy;
  // Unit vector along [w]; the [h] side is perpendicular to it.
  final double ex;
  final double ey;
  final double w;
  final double h;

  const _Rect(this.cx, this.cy, this.ex, this.ey, this.w, this.h);
}

/// Smallest rotated rectangle around the points (convex hull + rotating
/// calipers), like cv2.minAreaRect.
_Rect? _minAreaRect(List<int> xs, List<int> ys) {
  final hull = _convexHull(xs, ys);
  if (hull.length < 3) return null;
  _Rect? best;
  var bestArea = double.infinity;
  for (var i = 0; i < hull.length; i++) {
    final a = hull[i];
    final b = hull[(i + 1) % hull.length];
    final len = a.distanceTo(b);
    if (len == 0) continue;
    final ex = (b.x - a.x) / len;
    final ey = (b.y - a.y) / len;
    var minU = double.infinity, maxU = -double.infinity;
    var minV = double.infinity, maxV = -double.infinity;
    for (final p in hull) {
      final u = p.x * ex + p.y * ey;
      final v = -p.x * ey + p.y * ex;
      if (u < minU) minU = u;
      if (u > maxU) maxU = u;
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final area = (maxU - minU) * (maxV - minV);
    if (area < bestArea) {
      bestArea = area;
      final cu = (minU + maxU) / 2;
      final cv = (minV + maxV) / 2;
      best = _Rect(
        cu * ex - cv * ey,
        cu * ey + cv * ex,
        ex,
        ey,
        maxU - minU,
        maxV - minV,
      );
    }
  }
  return best;
}

/// Andrew's monotone chain; returns the hull counter-clockwise.
List<math.Point<double>> _convexHull(List<int> xs, List<int> ys) {
  final pts = [
    for (var i = 0; i < xs.length; i++)
      math.Point<double>(xs[i].toDouble(), ys[i].toDouble()),
  ]..sort((a, b) => a.x != b.x ? a.x.compareTo(b.x) : a.y.compareTo(b.y));
  if (pts.length < 3) return pts;
  double cross(
    math.Point<double> o,
    math.Point<double> a,
    math.Point<double> b,
  ) => (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
  final lower = <math.Point<double>>[];
  for (final p in pts) {
    while (lower.length >= 2 &&
        cross(lower[lower.length - 2], lower.last, p) <= 0) {
      lower.removeLast();
    }
    lower.add(p);
  }
  final upper = <math.Point<double>>[];
  for (final p in pts.reversed) {
    while (upper.length >= 2 &&
        cross(upper[upper.length - 2], upper.last, p) <= 0) {
      upper.removeLast();
    }
    upper.add(p);
  }
  lower.removeLast();
  upper.removeLast();
  return [...lower, ...upper];
}

double _meanProbInside(Float32List prob, int w, int h, _Rect r) {
  final hw = r.w / 2 + 0.5;
  final hh = r.h / 2 + 0.5;
  final reach = hw.abs() + hh.abs();
  final x0 = math.max(0, (r.cx - reach).floor());
  final x1 = math.min(w - 1, (r.cx + reach).ceil());
  final y0 = math.max(0, (r.cy - reach).floor());
  final y1 = math.min(h - 1, (r.cy + reach).ceil());
  var sum = 0.0;
  var count = 0;
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final dx = x - r.cx;
      final dy = y - r.cy;
      final u = dx * r.ex + dy * r.ey;
      final v = -dx * r.ey + dy * r.ex;
      if (u.abs() <= hw && v.abs() <= hh) {
        sum += prob[y * w + x];
        count++;
      }
    }
  }
  return count == 0 ? 0 : sum / count;
}

/// Long side becomes the reading direction (vertical text: top to bottom).
TextQuad _toReadingQuad(
  _Rect r,
  double scaleX,
  double scaleY,
  int imageWidth,
  int imageHeight,
) {
  double ux, uy, long, short;
  if (r.w >= r.h) {
    ux = r.ex;
    uy = r.ey;
    long = r.w;
    short = r.h;
  } else {
    ux = -r.ey;
    uy = r.ex;
    long = r.h;
    short = r.w;
  }
  final horizontal = ux.abs() >= uy.abs();
  if ((horizontal && ux < 0) || (!horizontal && uy < 0)) {
    ux = -ux;
    uy = -uy;
  }
  // Perpendicular, pointing "down" relative to the text.
  final vx = -uy;
  final vy = ux;

  math.Point<double> corner(double a, double b) {
    final x = (r.cx + ux * a + vx * b) * scaleX;
    final y = (r.cy + uy * a + vy * b) * scaleY;
    return math.Point(
      x.clamp(0, imageWidth - 1).toDouble(),
      y.clamp(0, imageHeight - 1).toDouble(),
    );
  }

  return TextQuad([
    corner(-long / 2, -short / 2),
    corner(long / 2, -short / 2),
    corner(long / 2, short / 2),
    corner(-long / 2, short / 2),
  ]);
}

/// Reading order; lines within 10 px vertically share a row (sorted_boxes).
List<TextQuad> _sortReadingOrder(List<TextQuad> quads) {
  final sorted = [...quads]
    ..sort((a, b) {
      final dy = a.corners[0].y.compareTo(b.corners[0].y);
      return dy != 0 ? dy : a.corners[0].x.compareTo(b.corners[0].x);
    });
  for (var i = 0; i < sorted.length - 1; i++) {
    for (var j = i; j >= 0; j--) {
      final a = sorted[j].corners[0];
      final b = sorted[j + 1].corners[0];
      if ((b.y - a.y).abs() < 10 && b.x < a.x) {
        final t = sorted[j];
        sorted[j] = sorted[j + 1];
        sorted[j + 1] = t;
      } else {
        break;
      }
    }
  }
  return sorted;
}

const int recHeight = 48;
const int _recMinWidth = 320;
const int _recMaxWidth = 1600;

/// Crops each line level into the 48 px model input, batched by width.
List<RecBatch> buildRecBatches(
  RgbaImage image,
  List<TextQuad> quads, {
  int maxBatch = 8,
}) {
  final widths = [
    for (final q in quads)
      (recHeight * q.width / math.max(q.height, 1))
          .ceil()
          .clamp(1, _recMaxWidth)
          .toInt(),
  ];
  final order = List<int>.generate(quads.length, (i) => i)
    ..sort((a, b) => widths[a].compareTo(widths[b]));

  final batches = <RecBatch>[];
  for (var s = 0; s < order.length; s += maxBatch) {
    final idx = order.sublist(s, math.min(s + maxBatch, order.length));
    final batchWidth = math.max(
      _recMinWidth,
      idx.map((i) => widths[i]).reduce(math.max),
    );
    final plane = recHeight * batchWidth;
    final data = Float32List(idx.length * 3 * plane);
    final rgb = Float64List(3);

    for (var b = 0; b < idx.length; b++) {
      final q = quads[idx[b]];
      final tw = widths[idx[b]];
      final tl = q.corners[0];
      final tr = q.corners[1];
      final bl = q.corners[3];
      final ux = (tr.x - tl.x) / tw;
      final uy = (tr.y - tl.y) / tw;
      final vx = (bl.x - tl.x) / recHeight;
      final vy = (bl.y - tl.y) / recHeight;
      // Average a few sub-samples when shrinking a lot, to avoid aliasing.
      final step = math.max(
        math.sqrt(ux * ux + uy * uy),
        math.sqrt(vx * vx + vy * vy),
      );
      final k = step.ceil().clamp(1, 4).toInt();
      final base = b * 3 * plane;

      for (var y = 0; y < recHeight; y++) {
        for (var x = 0; x < tw; x++) {
          var r = 0.0, g = 0.0, bl0 = 0.0;
          for (var sy = 0; sy < k; sy++) {
            final fy = y + (sy + 0.5) / k;
            for (var sx = 0; sx < k; sx++) {
              final fx = x + (sx + 0.5) / k;
              _sampleBilinear(
                image,
                tl.x + ux * fx + vx * fy - 0.5,
                tl.y + uy * fx + vy * fy - 0.5,
                rgb,
              );
              r += rgb[0];
              g += rgb[1];
              bl0 += rgb[2];
            }
          }
          final n = (k * k).toDouble();
          final i = y * batchWidth + x;
          data[base + i] = (bl0 / n / 255 - 0.5) / 0.5;
          data[base + plane + i] = (g / n / 255 - 0.5) / 0.5;
          data[base + 2 * plane + i] = (r / n / 255 - 0.5) / 0.5;
        }
      }
    }
    batches.add(RecBatch(data, batchWidth, idx));
  }
  return batches;
}

/// CTC greedy decode: drop repeats and blanks (index 0).
RecognizedText decodeCtc(
  List<int> indices,
  List<double> scores,
  int offset,
  int steps,
  List<String> dictionary, {
  bool rightToLeft = false,
}) {
  final chars = StringBuffer();
  var confidence = 0.0;
  var count = 0;
  var previous = -1;
  for (var t = 0; t < steps; t++) {
    final index = indices[offset + t];
    if (index != previous && index != 0 && index - 1 < dictionary.length) {
      chars.write(dictionary[index - 1]);
      confidence += scores[offset + t];
      count++;
    }
    previous = index;
  }
  var text = chars.toString();
  if (rightToLeft) text = _reverseRightToLeft(text);
  return RecognizedText(text.trim(), count == 0 ? 0 : confidence / count);
}

/// Reverses RTL text but keeps Latin/digit runs in order (pred_reverse).
String _reverseRightToLeft(String text) {
  final keep = RegExp(r'[a-zA-Z0-9 :*./%+\-]');
  final parts = <String>[];
  var run = StringBuffer();
  for (final c in text.characters) {
    if (keep.hasMatch(c)) {
      run.write(c);
    } else {
      if (run.isNotEmpty) {
        parts.add(run.toString());
        run = StringBuffer();
      }
      parts.add(c);
    }
  }
  if (run.isNotEmpty) parts.add(run.toString());
  return parts.reversed.join();
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}

/// Background and text color of a line (0xAARRGGBB).
class LabelColors {
  final int background;
  final int foreground;

  const LabelColors(this.background, this.foreground);
}

LabelColors sampleLabelColors(RgbaImage image, TextQuad quad) {
  final c = quad.corners;
  final rgb = Float64List(3);

  // The quad was grown past the letters, so its edges lie on the background.
  const edgeSamples = 16;
  final rs = <double>[], gs = <double>[], bs = <double>[];
  for (var e = 0; e < 4; e++) {
    final a = c[e];
    final b = c[(e + 1) % 4];
    for (var i = 0; i < edgeSamples; i++) {
      final t = (i + 0.5) / edgeSamples;
      _sampleBilinear(
        image,
        a.x + (b.x - a.x) * t - 0.5,
        a.y + (b.y - a.y) * t - 0.5,
        rgb,
      );
      rs.add(rgb[0]);
      gs.add(rgb[1]);
      bs.add(rgb[2]);
    }
  }
  final bgR = _median(rs), bgG = _median(gs), bgB = _median(bs);

  // The letters: the inside pixels least like the background.
  const across = 32, down = 8;
  final tl = c[0], tr = c[1], bl = c[3];
  final samples = <(double, double, double, double)>[];
  for (var j = 0; j < down; j++) {
    final v = 0.15 + 0.7 * (j + 0.5) / down;
    for (var i = 0; i < across; i++) {
      final u = 0.05 + 0.9 * (i + 0.5) / across;
      _sampleBilinear(
        image,
        tl.x + (tr.x - tl.x) * u + (bl.x - tl.x) * v - 0.5,
        tl.y + (tr.y - tl.y) * u + (bl.y - tl.y) * v - 0.5,
        rgb,
      );
      final dr = rgb[0] - bgR, dg = rgb[1] - bgG, db = rgb[2] - bgB;
      samples.add((dr * dr + dg * dg + db * db, rgb[0], rgb[1], rgb[2]));
    }
  }
  samples.sort((a, b) => b.$1.compareTo(a.$1));
  final ink = samples.take(math.max(1, samples.length * 15 ~/ 100));
  var fgR = 0.0, fgG = 0.0, fgB = 0.0;
  for (final s in ink) {
    fgR += s.$2;
    fgG += s.$3;
    fgB += s.$4;
  }
  final n = ink.length;
  fgR /= n;
  fgG /= n;
  fgB /= n;

  // Too close to the background to read: plain black or white instead.
  final dr = fgR - bgR, dg = fgG - bgG, db = fgB - bgB;
  if (dr * dr + dg * dg + db * db < 90 * 90) {
    final luminance = 0.299 * bgR + 0.587 * bgG + 0.114 * bgB;
    fgR = fgG = fgB = luminance > 140 ? 0 : 255;
  }
  return LabelColors(_argb(bgR, bgG, bgB), _argb(fgR, fgG, fgB));
}

double _median(List<double> values) {
  values.sort();
  return values[values.length ~/ 2];
}

int _argb(double r, double g, double b) =>
    0xFF000000 |
    (r.round().clamp(0, 255) << 16) |
    (g.round().clamp(0, 255) << 8) |
    b.round().clamp(0, 255);

/// Bilinear sample at a pixel-center coordinate; writes R, G, B into [out].
void _sampleBilinear(RgbaImage img, double fx, double fy, Float64List out) {
  final w = img.width;
  final h = img.height;
  final p = img.pixels;
  if (fx < 0) fx = 0;
  if (fy < 0) fy = 0;
  if (fx > w - 1) fx = (w - 1).toDouble();
  if (fy > h - 1) fy = (h - 1).toDouble();
  final x0 = fx.floor();
  final y0 = fy.floor();
  final x1 = x0 + 1 < w ? x0 + 1 : x0;
  final y1 = y0 + 1 < h ? y0 + 1 : y0;
  final ax = fx - x0;
  final ay = fy - y0;
  final i00 = (y0 * w + x0) * 4;
  final i01 = (y0 * w + x1) * 4;
  final i10 = (y1 * w + x0) * 4;
  final i11 = (y1 * w + x1) * 4;
  for (var c = 0; c < 3; c++) {
    final top = p[i00 + c] * (1 - ax) + p[i01 + c] * ax;
    final bottom = p[i10 + c] * (1 - ax) + p[i11 + c] * ax;
    out[c] = top * (1 - ay) + bottom * ay;
  }
}
