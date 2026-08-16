import '../../domain/entities/translation_entity.dart';
import '../../domain/repositories/translation_repository.dart';
import '../services/gemini_service.dart';

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
}
