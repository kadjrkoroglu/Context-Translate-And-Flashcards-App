/// Longest card sides; Study with AI has the learner type the word exactly.
const int maxCardWordLength = 40;
const int maxCardTranslationLength = 60;

bool fitsCard(String word, String translation) =>
    word.trim().length <= maxCardWordLength &&
    translation.trim().length <= maxCardTranslationLength;

/// A study day starts at 4 AM, so late-night study counts as that evening.
const int dayStartHour = 4;

DateTime studyDay(DateTime time) {
  final t = time.subtract(const Duration(hours: dayStartHour));
  return DateTime(t.year, t.month, t.day);
}

class CardEntity {
  final int id;
  final String syncId;
  String word;
  String translation;
  final DateTime createdAt;
  DateTime lastModified;

  DateTime? nextReviewDate;
  double easeFactor = 2.5;
  int interval = 0;
  int repetitions = 0;
  bool isNewCard = true;
  DateTime? lastStudiedDate;
  int? lastRatingIndex;

  /// The day the card stopped being new; counts toward the daily new limit.
  DateTime? firstStudiedAt;

  DateTime? aiStudiedAt;
  bool aiNeedsReview = false;

  /// Null when unknown (auto-detect, typed by hand); the voice then guesses.
  String? wordLanguage;
  String? translationLanguage;

  /// Example sentences and their translations, the word marked with [[ ]].
  List<String>? exampleSentences;
  List<String>? exampleTranslations;

  String? userId;
  String? remoteId;
  bool isSynced = false;
  bool isDeleted = false;
  String? deckSyncId;

  /// Missed and not remembered yet: due again within minutes.
  bool get isLearning => !isNewCard && interval == 0;

  CardEntity({
    required this.id,
    required this.syncId,
    required this.word,
    required this.translation,
    required this.createdAt,
    required this.lastModified,
    this.nextReviewDate,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.isNewCard = true,
    this.lastStudiedDate,
    this.lastRatingIndex,
    this.firstStudiedAt,
    this.aiStudiedAt,
    this.aiNeedsReview = false,
    this.wordLanguage,
    this.translationLanguage,
    this.exampleSentences,
    this.exampleTranslations,
    this.userId,
    this.remoteId,
    this.isSynced = false,
    this.isDeleted = false,
    this.deckSyncId,
  });
}
