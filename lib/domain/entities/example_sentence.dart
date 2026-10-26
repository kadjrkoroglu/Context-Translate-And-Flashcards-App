import 'package:translate_app/domain/entities/card_entity.dart';

/// A sentence using a word, and its translation. The word is marked with
/// [[ ]] in both, e.g. "We [[booked]] a table."
class ExampleSentence {
  final String sentence;
  final String translation;

  const ExampleSentence({required this.sentence, required this.translation});
}

/// Example sentences are for card-sized text of up to 5 words; longer text
/// mixes up the meaning. Chinese and Japanese have no spaces: 12 characters.
bool fitsExamples(String text) {
  final t = text.trim();
  if (t.isEmpty || t.length > maxCardWordLength || t.contains('\n')) {
    return false;
  }
  if (RegExp(r'[\u3040-\u30ff\u3400-\u9fff]').hasMatch(t)) {
    return t.length <= 12;
  }
  return t.split(RegExp(r'\s+')).length <= 5;
}

extension CardExamples on CardEntity {
  /// Null until fetched once.
  List<ExampleSentence>? get examples {
    final sentences = exampleSentences, translations = exampleTranslations;
    if (sentences == null || translations == null || sentences.isEmpty) {
      return null;
    }
    if (sentences.length != translations.length) return null;
    return [
      for (var i = 0; i < sentences.length; i++)
        ExampleSentence(sentence: sentences[i], translation: translations[i]),
    ];
  }
}
