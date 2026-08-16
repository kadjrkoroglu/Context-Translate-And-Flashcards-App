import '../entities/translation_entity.dart';
import '../repositories/translation_repository.dart';

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
}
