import '../entities/translation_entity.dart';
import '../repositories/translation_repository.dart';
import '../entities/live_session_grant.dart';
import '../entities/photo_translation.dart';
import '../entities/study_session.dart';

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

  Future<StudyState> fetchStudyState() => _repository.fetchStudyState();

  Future<StudyStart> startStudy({
    required String deckId,
    required String deckName,
    required List<({String id, String word, String translation})> cards,
  }) =>
      _repository.startStudy(deckId: deckId, deckName: deckName, cards: cards);

  Future<StudyReply> answerStudy(String sessionId, String answer) =>
      _repository.answerStudy(sessionId, answer);
}
