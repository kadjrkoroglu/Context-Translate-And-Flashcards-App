import 'dart:math';
import '../../domain/entities/card_entity.dart';

enum StudyRating { again, hard, good, easy }

class SRSService {
  static CardEntity calculateNextReview(CardEntity card, StudyRating rating) {
    final now = DateTime.now();

    // Again - Reset progress
    if (rating == StudyRating.again) {
      card.repetitions = 0;
      card.interval = 0;
    } else {
      // SM-2 Algorithm
      if (card.repetitions == 0) {
        // First time studying: New Card
        if (rating == StudyRating.easy) {
          card.interval = 4;
          card.easeFactor = 2.5;
        } else {
          card.interval = 1;
        }
      } else if (card.repetitions == 1) {
        // Second rep: 6 days (SM-2)
        card.interval = 6;
      } else {
        // Resulting reps: Interval * EaseFactor
        int q = 3; // Default: hard
        if (rating == StudyRating.good) q = 4;
        if (rating == StudyRating.easy) q = 5;

        // Ease Factor (EF) update
        card.easeFactor =
            card.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
        if (card.easeFactor < 1.3) card.easeFactor = 1.3;

        // Calculate new interval
        card.interval = (card.interval * card.easeFactor).round();
      }

      // Increment repetitions
      card.repetitions += 1;
    }

    // Fuzz Calculation
    int fuzzedInterval = card.interval;
    if (fuzzedInterval > 0) {
      final fuzzDays = (fuzzedInterval * 0.05).round();
      if (fuzzDays > 0) {
        final random = Random();
        final modifier = random.nextInt(fuzzDays * 2 + 1) - fuzzDays;
        fuzzedInterval += modifier;
      }
      // Prevent "Easy" or successfully learned cards from falling to today (0 days)
      if (fuzzedInterval < 1) fuzzedInterval = 1;
    }

    // Schedule next review
    if (rating == StudyRating.again) {
      // If "Again" is selected, card is shown again immediately (within 1 minute)
      card.nextReviewDate = now.add(const Duration(minutes: 1));
    } else {
      // In other cases, schedule for a future day
      card.nextReviewDate = DateTime(
        now.year,
        now.month,
        now.day + fuzzedInterval,
        now.hour,
        now.minute,
      );
    }

    card.isNewCard = false;
    card.lastStudiedDate = now;
    card.lastRatingIndex = rating.index;

    return card;
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
