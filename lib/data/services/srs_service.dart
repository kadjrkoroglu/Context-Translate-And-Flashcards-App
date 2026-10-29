import 'dart:math';
import '../../domain/entities/card_entity.dart';

enum StudyRating { again, hard, good, easy }

/// Anki's defaults: missed cards repeat in the session, reviews spread by ease.
class SRSService {
  static const againDelay = Duration(minutes: 1);
  static const hardDelay = Duration(minutes: 5);
  static const graduatingInterval = 1;
  static const easyInterval = 4;
  static const hardFactor = 1.2;
  static const easyBonus = 1.3;
  static const minEase = 1.3;
  static const maxInterval = 365;

  static final _random = Random();

  static CardEntity calculateNextReview(
    CardEntity card,
    StudyRating rating, {
    DateTime? now,
    Random? random,
  }) {
    now ??= DateTime.now();
    final days = card.isNewCard || card.interval == 0
        ? _learn(rating)
        : _review(card, rating, now);

    if (days == null) {
      card.interval = 0;
      card.repetitions = 0;
      card.nextReviewDate = now.add(
        rating == StudyRating.hard ? hardDelay : againDelay,
      );
    } else {
      card.interval = min(maxInterval, _fuzz(days, random ?? _random));
      card.repetitions += 1;
      // Due from the start of that study day, not at this hour.
      final day = studyDay(now);
      card.nextReviewDate = DateTime(
        day.year,
        day.month,
        day.day + card.interval,
        dayStartHour,
      );
    }

    if (card.isNewCard) card.firstStudiedAt = now;
    card.isNewCard = false;
    card.lastStudiedDate = now;
    card.lastRatingIndex = rating.index;

    return card;
  }

  /// Days until the next review; null keeps the card in the session.
  static int? _learn(StudyRating rating) => switch (rating) {
    StudyRating.again || StudyRating.hard => null,
    StudyRating.good => graduatingInterval,
    StudyRating.easy => easyInterval,
  };

  static int? _review(CardEntity card, StudyRating rating, DateTime now) {
    final interval = card.interval;
    final ease = card.easeFactor;
    // Remembered after a longer break than planned counts for more.
    final late = max(0, _daysBetween(card.nextReviewDate ?? now, now));
    final hard = max(interval + 1, (interval * hardFactor).round());
    final good = max(hard + 1, ((interval + late / 2) * ease).round());
    final easy = max(good + 1, ((interval + late) * ease * easyBonus).round());

    switch (rating) {
      case StudyRating.again:
        card.easeFactor = max(minEase, ease - 0.2);
        return null;
      case StudyRating.hard:
        card.easeFactor = max(minEase, ease - 0.15);
        return hard;
      case StudyRating.good:
        return good;
      case StudyRating.easy:
        card.easeFactor = ease + 0.15;
        return easy;
    }
  }

  /// Spreads cards studied together over nearby days (±5%).
  static int _fuzz(int days, Random random) {
    if (days < 3) return days;
    final spread = max(1, (days * 0.05).round());
    return days - spread + random.nextInt(2 * spread + 1);
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final a = studyDay(from), b = studyDay(to);
    return DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  }

  static String getRatingLabel(StudyRating rating) {
    switch (rating) {
      case StudyRating.again:
        return 'AGAIN';
      case StudyRating.good:
        return 'GOOD';
      case StudyRating.easy:
        return 'EASY';
      case StudyRating.hard:
        return 'HARD';
    }
  }

  static StudyRating? getRatingFromIndex(int? index) {
    if (index == null) return null;
    if (index < 0 || index >= StudyRating.values.length) return null;
    return StudyRating.values[index];
  }
}
