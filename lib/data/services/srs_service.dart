import 'dart:math';
import '../models/card_model.dart';

enum StudyRating { again, hard, good, easy }

class SRSService {
  static CardItem calculateNextReview(CardItem card, StudyRating rating) {
    final now = DateTime.now();

    // 1. Case: Again - Reset progress
    if (rating == StudyRating.again) {
      card.repetitions = 0;
      card.interval = 0;
    } else {
      // 2. Case: SM-2 Algorithm Implementation
      if (card.repetitions == 0) {
        // First time studying: New Card
        if (rating == StudyRating.easy) {
          card.interval = 4;
          card.easeFactor = 2.5;
        } else {
          card.interval = 1;
        }
      } else if (card.repetitions == 1) {
        // Second repetition: Always 6 days per SM-2 rule
        card.interval = 6;
      } else {
        // 3rd and subsequent repetitions: Interval * EaseFactor
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

      // Repetition increment should be done after calculation per SM-2 logic
      card.repetitions += 1;
    }

    // 3. Fuzz (Random Deviation) Calculation
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

    // 4. Next Review Date Assignment (Day vs Minute distinction)
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
