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

  String? userId;
  String? remoteId;
  bool isSynced = false;
  bool isDeleted = false;
  String? deckSyncId;

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
    this.userId,
    this.remoteId,
    this.isSynced = false,
    this.isDeleted = false,
    this.deckSyncId,
  });
}
