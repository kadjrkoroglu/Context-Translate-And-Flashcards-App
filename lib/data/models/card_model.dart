import 'package:isar/isar.dart';

part 'card_model.g.dart';

@collection
class CardItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String syncId;

  late String word;
  late String translation;
  late DateTime createdAt;
  late DateTime lastModified;

  // For "study" logic
  DateTime? nextReviewDate;
  // SM-2 Algorithm parameters
  double easeFactor = 2.5;
  int interval = 0; // In days
  int repetitions = 0;
  bool isNewCard = true;
  DateTime? lastStudiedDate;

  int?
  lastRatingIndex; // For tracking last rating (0=again, 1=hard, 2=good, 3=easy)

  String? userId;
  String? remoteId;
  bool isSynced = false;
  bool isDeleted = false;

  // Store parent deck's syncId so we can re-link after sync
  String? deckSyncId;

  Map<String, dynamic> toMap() {
    return {
      'syncId': syncId,
      'word': word,
      'translation': translation,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'easeFactor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'isNewCard': isNewCard,
      'lastStudiedDate': lastStudiedDate?.toIso8601String(),
      'lastRatingIndex': lastRatingIndex,
      'userId': userId,
      'isDeleted': isDeleted,
      'deckSyncId': deckSyncId,
    };
  }

  static CardItem fromMap(Map<String, dynamic> map, {String? remoteId}) {
    return CardItem()
      ..syncId = map['syncId'] ?? remoteId ?? ''
      ..word = map['word'] ?? ''
      ..translation = map['translation'] ?? ''
      ..createdAt = DateTime.parse(map['createdAt'])
      ..lastModified = map['lastModified'] != null
          ? DateTime.parse(map['lastModified'])
          : DateTime.parse(map['createdAt'])
      ..nextReviewDate = map['nextReviewDate'] != null
          ? DateTime.parse(map['nextReviewDate'])
          : null
      ..easeFactor = (map['easeFactor'] ?? 2.5).toDouble()
      ..interval = map['interval'] ?? 0
      ..repetitions = map['repetitions'] ?? 0
      ..isNewCard = map['isNewCard'] ?? true
      ..lastStudiedDate = map['lastStudiedDate'] != null
          ? DateTime.parse(map['lastStudiedDate'])
          : null
      ..lastRatingIndex = map['lastRatingIndex']
      ..userId = map['userId']
      ..remoteId = remoteId
      ..isSynced = true
      ..isDeleted = map['isDeleted'] ?? false
      ..deckSyncId = map['deckSyncId'];
  }
}
