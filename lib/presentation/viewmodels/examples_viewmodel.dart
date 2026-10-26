import 'package:translate_app/domain/entities/example_sentence.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';

/// Example sentences from the AI, kept for the session so a word costs one
/// request, and a card saved after looking them up gets them too.
class ExamplesViewModel {
  final TranslateUsecase _usecase;
  final Map<String, List<ExampleSentence>> _cache = {};

  ExamplesViewModel(this._usecase);

  // Cards start with a capital ("İ" lowercases to "i" plus a dot).
  static String _key(String text, String translation) =>
      '${text.trim().toLowerCase()}|${translation.trim().toLowerCase()}'
          .replaceAll('̇', '');

  List<ExampleSentence>? cached(String text, String translation) =>
      _cache[_key(text, translation)];

  /// Unknown (null) languages are recognized by the AI.
  Future<List<ExampleSentence>> load({
    required String text,
    required String translation,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    final key = _key(text, translation);
    if (_cache[key] case final hit?) return hit;
    final examples = await _usecase.exampleSentences(
      text: text.trim(),
      translation: translation.trim(),
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    if (examples.isNotEmpty) _cache[key] = examples;
    return examples;
  }
}
