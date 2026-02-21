import 'package:isar/isar.dart';

part 'card_model.g.dart';

@collection
class CardItem {
  Id id = Isar.autoIncrement;

  late String word;
  late String translation;
  late DateTime createdAt;

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
}
