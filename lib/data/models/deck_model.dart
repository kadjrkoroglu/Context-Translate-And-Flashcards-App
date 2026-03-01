import 'package:isar/isar.dart';
import 'package:translate_app/data/models/card_model.dart';

part 'deck_model.g.dart';

@collection
class DeckItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String syncId;

  late String name;
  late DateTime createdAt;
  late DateTime lastModified;

  int newCardsLimit = 20;
  int reviewsLimit = 200;

  final cards = IsarLinks<CardItem>();

  int? orderIndex;

  String? userId;
  String? remoteId;
  bool isSynced = false;
  bool isDeleted = false;

  Map<String, dynamic> toMap() {
    return {
      'syncId': syncId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'newCardsLimit': newCardsLimit,
      'reviewsLimit': reviewsLimit,
      'orderIndex': orderIndex,
      'userId': userId,
      'isDeleted': isDeleted,
    };
  }

  static DeckItem fromMap(Map<String, dynamic> map, {String? remoteId}) {
    return DeckItem()
      ..syncId = map['syncId'] ?? remoteId ?? ''
      ..name = map['name'] ?? ''
      ..createdAt = DateTime.parse(map['createdAt'])
      ..lastModified = map['lastModified'] != null
          ? DateTime.parse(map['lastModified'])
          : DateTime.parse(map['createdAt'])
      ..newCardsLimit = map['newCardsLimit'] ?? 20
      ..reviewsLimit = map['reviewsLimit'] ?? 200
      ..orderIndex = map['orderIndex']
      ..userId = map['userId']
      ..remoteId = remoteId
      ..isSynced = true
      ..isDeleted = map['isDeleted'] ?? false;
  }
}
