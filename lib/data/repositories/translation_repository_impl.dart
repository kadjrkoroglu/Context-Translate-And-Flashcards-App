import '../../domain/entities/translation_entity.dart';
import '../../domain/repositories/translation_repository.dart';
import '../services/gemini_service.dart';
import '../../domain/entities/example_sentence.dart';
import '../../domain/entities/live_session_grant.dart';
import '../../domain/entities/photo_translation.dart';
import '../../domain/entities/study_session.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final GeminiService _geminiService;

  TranslationRepositoryImpl(this._geminiService);

  @override
  Future<TranslationEntity> translate(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final translations = await _geminiService.translateText(text, targetLang);
    return TranslationEntity(
      originalText: text,
      translatedText: translations.join(' | '),
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
    );
  }

  @override
  Future<PhotoTranslation> translatePhotoBlocks(
    List<List<String>> blocks,
    String targetLang,
  ) {
    return _geminiService.translatePhotoBlocks(blocks, targetLang);
  }

  @override
  Future<List<ExampleSentence>> exampleSentences({
    required String text,
    required String translation,
    String? sourceLanguage,
    String? targetLanguage,
  }) => _geminiService.exampleSentences(
    text: text,
    translation: translation,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
  );

  @override
  Future<LiveSessionGrant> startLiveSession(String targetLanguageCode) {
    return _geminiService.startLiveSession(targetLanguageCode);
  }

  @override
  Future<int?> endLiveSession(String sessionId) {
    return _geminiService.endLiveSession(sessionId);
  }

  @override
  Future<StudyState> fetchStudyState() => _geminiService.fetchStudyState();

  @override
  Future<StudyStart> startStudy({
    required String deckId,
    required String deckName,
    required List<({String id, String word, String translation})> cards,
  }) => _geminiService.startStudy(
    deckId: deckId,
    deckName: deckName,
    cards: cards,
  );

  @override
  Future<StudyReply> answerStudy(String sessionId, String answer) =>
      _geminiService.answerStudy(sessionId, answer);

  @override
  Future<StudyState> endStudy(String sessionId) =>
      _geminiService.endStudy(sessionId);
}
