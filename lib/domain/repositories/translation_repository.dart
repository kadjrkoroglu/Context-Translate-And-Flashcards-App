import '../entities/translation_entity.dart';

abstract class TranslationRepository {
  Future<TranslationEntity> translate(
    String text,
    String sourceLang,
    String targetLang,
  );
}
