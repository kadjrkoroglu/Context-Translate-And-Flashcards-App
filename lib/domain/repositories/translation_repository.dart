import '../entities/translation_entity.dart';
import '../entities/photo_translation.dart';

abstract class TranslationRepository {
  Future<TranslationEntity> translate(
    String text,
    String sourceLang,
    String targetLang,
  );

  /// Translates text lines read from a photo on the device; one translation
  /// per line, in the same order.
  Future<PhotoTranslation> translatePhotoLines(
    List<String> lines,
    String sourceLang,
    String targetLang,
  );
}
