import 'dart:math';

import 'package:translate_app/domain/entities/card_entity.dart';

/// Cards in one Study with AI session (the backend expects exactly this many).
const int studySessionCards = 10;
const int _maxCardText = 200;
const int _maxReviewCards = 3;

bool isStudyCard(CardEntity card) =>
    !card.isDeleted &&
    card.word.trim().isNotEmpty &&
    card.translation.trim().isNotEmpty &&
    card.word.length <= _maxCardText &&
    card.translation.length <= _maxCardText;

int studyCardCount(List<CardEntity> cards) => cards.where(isStudyCard).length;

/// Needed-help cards (max 3), then never studied, then oldest; empty if too few.
List<CardEntity> pickStudyCards(List<CardEntity> cards, {Random? random}) {
  final rng = random ?? Random();
  final eligible = cards.where(isStudyCard).toList();
  if (eligible.length < studySessionCards) return const [];

  // A session's cards share one timestamp, so ties are broken at random.
  final tieBreak = {for (final card in eligible) card: rng.nextDouble()};
  int oldestFirst(CardEntity a, CardEntity b) {
    final byDate = (a.aiStudiedAt ?? DateTime(0)).compareTo(
      b.aiStudiedAt ?? DateTime(0),
    );
    return byDate != 0 ? byDate : tieBreak[a]!.compareTo(tieBreak[b]!);
  }

  final review = eligible.where((c) => c.aiNeedsReview).toList()
    ..sort(oldestFirst);
  final picked = review.take(_maxReviewCards).toList();
  final rest = eligible.where((c) => !picked.contains(c)).toList()
    ..sort(oldestFirst);
  picked.addAll(rest.take(studySessionCards - picked.length));
  return picked..shuffle(rng);
}
