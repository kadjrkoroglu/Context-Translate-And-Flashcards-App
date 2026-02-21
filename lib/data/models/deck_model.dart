import 'package:isar/isar.dart';
import 'package:translate_app/data/models/card_model.dart';

part 'deck_model.g.dart';

@collection
class DeckItem {
  Id id = Isar.autoIncrement;

  late String name;
  late DateTime createdAt;

  int newCardsLimit = 20;
  int reviewsLimit = 200;

  final cards = IsarLinks<CardItem>();

  int? orderIndex;
}
