import 'dart:math';
import '../models/card_model.dart';

enum StudyRating { again, hard, good, easy }

class SRSService {
  static CardItem calculateNextReview(CardItem card, StudyRating rating) {
    DateTime now = DateTime.now();
    DateTime nextReview;

    if (card.repetitions == 0) {
      // New cards
      switch (rating) {
        case StudyRating.again:
          card.interval = 0;
          card.repetitions = 0;
          break;
        case StudyRating.hard:
          card.interval = 1;
          card.repetitions = 1;
          break;
        case StudyRating.good:
          card.interval = 1;
          card.repetitions = 1;
          break;
        case StudyRating.easy:
          card.interval = 4;
          card.repetitions = 1;
          card.easeFactor = 2.5;
          break;
      }
    } else {
      // Learned cards
      if (rating == StudyRating.again) {
        card.repetitions = 0;
        card.interval = 1;
      } else {
        int q = 0;
        switch (rating) {
          case StudyRating.again:
            break; // Handled above
          case StudyRating.hard:
            q = 3;
            break;
          case StudyRating.good:
            q = 4;
            break;
          case StudyRating.easy:
            q = 5;
            break;
        }

        // Ease Factor (EF) Update
        card.easeFactor =
            card.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
        if (card.easeFactor < 1.3) {
          card.easeFactor = 1.3;
        }

        // Interval Calculation
        if (card.repetitions == 1) {
          card.interval = 6;
        } else {
          card.interval = (card.interval * card.easeFactor).round();
        }
        card.repetitions += 1;
      }
    }

    // Fuzz calculation (+/- 5%) to avoid clumping
    int fuzzedInterval = card.interval;
    if (fuzzedInterval > 0) {
      final fuzzDays = (fuzzedInterval * 0.05).round();
      if (fuzzDays > 0) {
        final random = Random();
        // random number between -fuzzDays and +fuzzDays
        final modifier = random.nextInt(fuzzDays * 2 + 1) - fuzzDays;
        fuzzedInterval += modifier;
      }
    }

    if (fuzzedInterval == 0 && rating == StudyRating.again) {
      nextReview = now; // Immediate review (same day)
    } else {
      nextReview = now.add(Duration(days: fuzzedInterval));
    }

    card.isNewCard = false; // Mark as not new
    card.lastStudiedDate = now;
    card.nextReviewDate = nextReview;
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
