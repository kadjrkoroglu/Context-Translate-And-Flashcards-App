import 'card_entity.dart';

class DeckEntity {
  final int id;
  final String syncId;
  final String name;
  final DateTime createdAt;
  DateTime lastModified;

  int newCardsLimit = 20;
  int reviewsLimit = 200;
  final List<CardEntity> cards;

  int? orderIndex;
  String? userId;
  String? remoteId;
  bool isSynced = false;
  bool isDeleted = false;

  DeckEntity({
    required this.id,
    required this.syncId,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    this.newCardsLimit = 20,
    this.reviewsLimit = 200,
    List<CardEntity>? cards,
    this.orderIndex,
    this.userId,
    this.remoteId,
    this.isSynced = false,
    this.isDeleted = false,
  }) : cards = cards ?? [];
}
