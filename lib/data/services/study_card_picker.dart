import 'dart:math';

import 'package:translate_app/domain/entities/card_entity.dart';

/// Cards in one Study with AI session (the backend accepts this range).
const int minStudyCards = 10;
const int maxStudyCards = 30;

bool isStudyCard(CardEntity card) =>
    !card.isDeleted &&
    card.word.trim().isNotEmpty &&
    card.translation.trim().isNotEmpty &&
    fitsCard(card.word, card.translation);

int studyCardCount(List<CardEntity> cards) => cards.where(isStudyCard).length;

/// Missed cards (up to 30% of the session), then never studied, then oldest;
/// empty if too few.
List<CardEntity> pickStudyCards(List<CardEntity> cards, {Random? random}) {
  final rng = random ?? Random();
  final eligible = cards.where(isStudyCard).toList();
  if (eligible.length < minStudyCards) return const [];
  final size = min(eligible.length, maxStudyCards);

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
  final picked = review.take(size * 3 ~/ 10).toList();
  final rest = eligible.where((c) => !picked.contains(c)).toList()
    ..sort(oldestFirst);
  picked.addAll(rest.take(size - picked.length));
  return picked..shuffle(rng);
}
