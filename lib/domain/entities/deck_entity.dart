import 'dart:math';

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

  /// New cards that can still be started today.
  int newCardsLeftToday(DateTime now) => max(
    0,
    newCardsLimit -
        _studiedToday(now, (c) => _sameDay(c.firstStudiedAt, now)).length,
  );

  /// Reviews left today; a card started today is not a review.
  int reviewsLeftToday(DateTime now) => max(
    0,
    reviewsLimit -
        _studiedToday(now, (c) => !_sameDay(c.firstStudiedAt, now)).length,
  );

  Iterable<CardEntity> _studiedToday(
    DateTime now,
    bool Function(CardEntity card) test,
  ) => cards.where(
    (c) => !c.isDeleted && _sameDay(c.lastStudiedDate, now) && test(c),
  );

  static bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}
