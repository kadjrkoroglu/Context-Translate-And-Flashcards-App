import '../entities/translation_entity.dart';
import '../repositories/translation_repository.dart';
import '../entities/live_session_grant.dart';
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

  Future<LiveSessionGrant> startLiveSession(String targetLanguageCode) {
    return _repository.startLiveSession(targetLanguageCode);
  }

  Future<int?> endLiveSession(String sessionId) {
    return _repository.endLiveSession(sessionId);
  }
}
