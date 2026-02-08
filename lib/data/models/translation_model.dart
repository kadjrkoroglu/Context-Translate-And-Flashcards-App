class TranslationModel {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;

  TranslationModel({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
