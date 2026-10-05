import '../entities/translation_entity.dart';
import '../entities/live_session_grant.dart';
import '../entities/photo_translation.dart';
import '../entities/study_session.dart';

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

  /// Reserves Live time and returns what is needed to connect.
  Future<LiveSessionGrant> startLiveSession(String targetLanguageCode);

  /// Gives back unused time; returns seconds left this month.
  Future<int?> endLiveSession(String sessionId);

  Future<StudyState> fetchStudyState();

  /// Starts a Study with AI session, or returns the unfinished one.
  Future<StudyStart> startStudy({
    required String deckId,
    required String deckName,
    required List<({String id, String word, String translation})> cards,
  });

  Future<StudyReply> answerStudy(String sessionId, String answer);
}
