/// Per group of lines: one translation for the whole group when its lines are
/// one text, else one per line. Plus a word list for flashcards.
class PhotoTranslation {
  final List<List<String>> translations;
  final List<PhotoWord> words;

  const PhotoTranslation({required this.translations, required this.words});
}

class PhotoWord {
  final String word;
  final String translation;

  const PhotoWord({required this.word, required this.translation});
}
