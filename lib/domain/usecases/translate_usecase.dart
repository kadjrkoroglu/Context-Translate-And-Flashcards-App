import '../entities/translation_entity.dart';
import '../repositories/translation_repository.dart';
import '../entities/photo_translation.dart';

class TranslateUsecase {
  final TranslationRepository _repository;

  TranslateUsecase(this._repository);

  Future<TranslationEntity> execute(
    String text,
    String sourceLang,
    String targetLang,
  ) {
    return _repository.translate(text, sourceLang, targetLang);
  }

  Future<PhotoTranslation> executePhotoLines(
    List<String> lines,
    String sourceLang,
    String targetLang,
  ) {
    return _repository.translatePhotoLines(lines, sourceLang, targetLang);
  }
}
