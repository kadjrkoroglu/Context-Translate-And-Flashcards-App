import '../entities/translation_entity.dart';
import '../entities/example_sentence.dart';
import '../entities/live_session_grant.dart';
import '../entities/photo_translation.dart';
import '../entities/study_session.dart';

abstract class TranslationRepository {
  Future<TranslationEntity> translate(
    String text,
    String sourceLang,
    String targetLang,
  );

  /// Translates groups of lines read from a photo on the device, in the
  /// same order.
  Future<PhotoTranslation> translatePhotoBlocks(
    List<List<String>> blocks,
    String targetLang,
  );

  /// Sentences using [text] in the meaning given by [translation].
  Future<List<ExampleSentence>> exampleSentences({
    required String text,
    required String translation,
    String? sourceLanguage,
    String? targetLanguage,
  });

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

  /// Ends the unfinished session; the usual break follows.
  Future<StudyState> endStudy(String sessionId);
}
