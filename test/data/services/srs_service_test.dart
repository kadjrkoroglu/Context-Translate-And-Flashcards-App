import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/data/services/srs_service.dart';
import 'package:translate_app/domain/entities/card_entity.dart';

/// No fuzz: always the middle of the range.
class Middle implements Random {
  @override
  int nextInt(int max) => max ~/ 2;
  @override
  double nextDouble() => 0.5;
  @override
  bool nextBool() => false;
}

/// Monday, 21:00.
final monday = DateTime(2026, 11, 2, 21);

CardEntity newCard() => CardEntity(
  id: 1,
  syncId: 'c1',
  word: 'word',
  translation: 'kelime',
  createdAt: monday,
  lastModified: monday,
);

/// A card on an [interval] day gap, due now unless [due] says otherwise.
CardEntity reviewCard(int interval, {double ease = 2.5, DateTime? due}) =>
    newCard()
      ..isNewCard = false
      ..interval = interval
      ..repetitions = 3
      ..easeFactor = ease
      ..nextReviewDate = due ?? monday;

CardEntity rate(CardEntity card, StudyRating rating, {DateTime? at}) =>
    SRSService.calculateNextReview(
      card,
      rating,
      now: at ?? monday,
      random: Middle(),
    );

void main() {
  group('A new card', () {
    test('Again and Hard keep it in the session', () {
      final again = rate(newCard(), StudyRating.again);
      expect(again.isLearning, isTrue);
      expect(again.nextReviewDate, monday.add(const Duration(minutes: 1)));

      final hard = rate(newCard(), StudyRating.hard);
      expect(hard.isLearning, isTrue);
      expect(hard.nextReviewDate, monday.add(const Duration(minutes: 5)));
    });

    test('Good is due the next day from 4 AM, Easy in 4 days', () {
      expect(
        rate(newCard(), StudyRating.good).nextReviewDate,
        DateTime(2026, 11, 3, 4),
      );
      expect(
        rate(newCard(), StudyRating.easy).nextReviewDate,
        DateTime(2026, 11, 6, 4),
      );
    });

    test('after midnight it still counts as the evening before', () {
      final card = rate(
        newCard(),
        StudyRating.good,
        at: DateTime(2026, 11, 3, 1),
      );
      expect(card.nextReviewDate, DateTime(2026, 11, 3, 4));
    });

    test('missed, then remembered: tomorrow, ease unchanged', () {
      final card = rate(rate(newCard(), StudyRating.again), StudyRating.good);
      expect(card.interval, 1);
      expect(card.easeFactor, 2.5);
    });
  });

  group('A review', () {
    test('Hard < Good < Easy', () {
      expect(rate(reviewCard(10), StudyRating.hard).interval, 12);
      expect(rate(reviewCard(10), StudyRating.good).interval, 25);
      expect(rate(reviewCard(10), StudyRating.easy).interval, 33);
    });

    test('Hard keeps it close and lowers the ease', () {
      final card = rate(reviewCard(15), StudyRating.hard);
      expect(card.interval, 18);
      expect(card.easeFactor, closeTo(2.35, 1e-9));
    });

    test('Easy raises the ease', () {
      final card = rate(reviewCard(10), StudyRating.easy);
      expect(card.easeFactor, closeTo(2.65, 1e-9));
    });

    test('Again: back in the session with less ease, then tomorrow', () {
      final card = rate(reviewCard(20), StudyRating.again);
      expect(card.isLearning, isTrue);
      expect(card.easeFactor, closeTo(2.3, 1e-9));
      expect(card.nextReviewDate, monday.add(const Duration(minutes: 1)));

      expect(rate(card, StudyRating.good).interval, 1);
    });

    test('remembered after a longer break counts for more', () {
      final late = reviewCard(
        10,
        due: monday.subtract(const Duration(days: 10)),
      );
      // (10 + 10 / 2) × 2.5
      expect(rate(late, StudyRating.good).interval, 38);
    });

    test('the ease stays at least 1.3', () {
      final card = rate(reviewCard(10, ease: 1.35), StudyRating.again);
      expect(card.easeFactor, 1.3);
    });

    test('at most a year apart', () {
      expect(rate(reviewCard(300), StudyRating.easy).interval, 365);
    });
  });

  test('fuzz moves a review by at most 5%', () {
    for (var i = 0; i < 200; i++) {
      final card = SRSService.calculateNextReview(
        reviewCard(40),
        StudyRating.good,
        now: monday,
      );
      expect(card.interval, inInclusiveRange(95, 105));
    }
  });
}
