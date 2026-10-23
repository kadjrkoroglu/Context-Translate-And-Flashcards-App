import 'dart:ui' show Color, Offset;

/// A line read from a photo, or several joined into one text. [corners]:
/// TL, TR, BR, BL relative to the photo (0-1); colors are sampled from it.
class PhotoTextBlock {
  final String text;
  final String translation;
  final List<Offset> corners;
  final Color background;
  final Color foreground;

  /// Photo lines it covers; padding and corners follow one line's size.
  final int lines;

  /// The photo's lines were centered (a caption), so the translation is too.
  final bool centered;

  const PhotoTextBlock({
    required this.text,
    required this.translation,
    required this.corners,
    required this.background,
    required this.foreground,
    this.lines = 1,
    this.centered = false,
  });

  PhotoTextBlock withTranslation(String translation) => PhotoTextBlock(
    text: text,
    translation: translation,
    corners: corners,
    background: background,
    foreground: foreground,
    lines: lines,
    centered: centered,
  );
}
