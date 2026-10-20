import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/data/services/srs_service.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';

final today = DateTime.now();

CardEntity card(int i) => CardEntity(
  id: i,
  syncId: 'c$i',
  word: 'word$i',
  translation: 'kelime$i',
  createdAt: today,
  lastModified: today,
);

DeckEntity deckOf(List<CardEntity> cards) => DeckEntity(
  id: 1,
  syncId: 'deck1',
  name: 'Deck',
  createdAt: today,
  lastModified: today,
  cards: cards,
);

void main() {
  test('20 of 40 new cards studied today leaves no new ones', () {
    final cards = [for (var i = 0; i < 40; i++) card(i)];
    final deck = deckOf(cards);
    for (final c in cards.take(20)) {
      SRSService.calculateNextReview(c, StudyRating.good);
    }

    expect(deck.newCardsLeftToday(DateTime.now()), 0);
    expect(deck.reviewsLeftToday(DateTime.now()), 200);
  });

  test('a review today does not count as a new card', () {
    final old = card(0)
      ..isNewCard = false
      ..repetitions = 2
      ..firstStudiedAt = today.subtract(const Duration(days: 10));
    final deck = deckOf([old, card(1)]);

    SRSService.calculateNextReview(old, StudyRating.good);

    expect(old.firstStudiedAt!.day, isNot(today.day));
    expect(deck.newCardsLeftToday(DateTime.now()), 20);
    expect(deck.reviewsLeftToday(DateTime.now()), 199);
  });

  test('the limit opens again the next day', () {
    final cards = [for (var i = 0; i < 25; i++) card(i)];
    final deck = deckOf(cards);
    for (final c in cards.take(20)) {
      SRSService.calculateNextReview(c, StudyRating.again);
    }

    expect(deck.newCardsLeftToday(DateTime.now()), 0);
    expect(deck.newCardsLeftToday(today.add(const Duration(days: 1))), 20);
  });
}
