import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/data/services/study_card_picker.dart';
import 'package:translate_app/domain/entities/card_entity.dart';

CardEntity card(
  String id, {
  DateTime? studied,
  bool review = false,
  bool deleted = false,
  String? word,
}) => CardEntity(
  id: 0,
  syncId: id,
  word: word ?? 'word $id',
  translation: 'kelime $id',
  createdAt: DateTime(2026),
  lastModified: DateTime(2026),
  aiStudiedAt: studied,
  aiNeedsReview: review,
  isDeleted: deleted,
);

List<CardEntity> cards(String prefix, int count, {DateTime? studied}) => [
  for (var i = 0; i < count; i++) card('$prefix$i', studied: studied),
];

Set<String> ids(List<CardEntity> picked) => {for (final c in picked) c.syncId};

void main() {
  test('fewer than 10 usable cards picks nothing', () {
    final deck = [
      ...cards('n', 9),
      card('deleted', deleted: true),
      card('long', word: 'x' * 201),
      card('blank', word: '  '),
    ];

    expect(studyCardCount(deck), 9);
    expect(pickStudyCards(deck), isEmpty);
  });

  test('never-studied cards come before studied ones', () {
    final deck = [
      ...cards('old', 5, studied: DateTime(2026, 9)),
      ...cards('new', 10),
    ];

    final picked = pickStudyCards(deck, random: Random(1));

    expect(picked, hasLength(10));
    expect(ids(picked), ids(cards('new', 10)));
  });

  test('then the cards studied longest ago', () {
    final deck = [
      ...cards('new', 4),
      ...cards('sept', 6, studied: DateTime(2026, 9, 1)),
      ...cards('oct', 6, studied: DateTime(2026, 10, 1)),
    ];

    final picked = ids(pickStudyCards(deck, random: Random(2)));

    expect(picked, {...ids(cards('new', 4)), ...ids(cards('sept', 6))});
  });

  test('at most 3 cards that needed help come back first', () {
    final deck = [
      for (var i = 0; i < 5; i++)
        card('help$i', studied: DateTime(2026, 9, 1 + i), review: true),
      ...cards('new', 20),
    ];

    final picked = ids(pickStudyCards(deck, random: Random(3)));

    expect(picked.where((id) => id.startsWith('help')), {
      'help0',
      'help1',
      'help2',
    });
    expect(picked.where((id) => id.startsWith('new')), hasLength(7));
  });

  test('once every card was studied it starts over with the oldest', () {
    final deck = [
      ...cards('first', 10, studied: DateTime(2026, 9, 1)),
      ...cards('second', 3, studied: DateTime(2026, 9, 2)),
    ];

    final picked = ids(pickStudyCards(deck, random: Random(4)));

    expect(picked, ids(cards('first', 10)));
  });

  test('picks at random among equally fresh cards', () {
    final deck = cards('new', 30);

    final a = ids(pickStudyCards(deck, random: Random(5)));
    final b = ids(pickStudyCards(deck, random: Random(6)));

    expect(a, hasLength(10));
    expect(a, isNot(equals(b)));
  });
}
