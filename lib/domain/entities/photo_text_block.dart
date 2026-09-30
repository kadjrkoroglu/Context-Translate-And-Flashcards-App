import 'dart:ui' show Color, Offset;

/// A line read from a photo. [corners]: TL, TR, BR, BL relative to the
/// photo (0-1); colors are sampled from the photo.
class PhotoTextBlock {
  final String text;
  final String translation;
  final List<Offset> corners;
  final Color background;
  final Color foreground;

  const PhotoTextBlock({
    required this.text,
    required this.translation,
    required this.corners,
    required this.background,
    required this.foreground,
  });

  PhotoTextBlock withTranslation(String translation) => PhotoTextBlock(
    text: text,
    translation: translation,
    corners: corners,
    background: background,
    foreground: foreground,
  );
}
