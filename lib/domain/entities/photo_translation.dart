/// One translation per line plus a word list for flashcards.
class PhotoTranslation {
  final List<String> translations;
  final List<PhotoWord> words;

  const PhotoTranslation({required this.translations, required this.words});
}

class PhotoWord {
  final String word;
  final String translation;

  const PhotoWord({required this.word, required this.translation});
}
