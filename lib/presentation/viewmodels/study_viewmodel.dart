import 'dart:math';

import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import '../../data/services/srs_service.dart';
import 'package:translate_app/l10n/l10n.dart';

class StudyViewModel extends ChangeNotifier {
  /// Missed cards due within this still come back before the session ends.
  static const _learnAhead = Duration(minutes: 20);

  final DeckUsecase _deckUsecase;
  DeckEntity _deck;

  List<CardEntity> _queue = [];
  int _completedCount = 0;
  int _totalSessionCards = 0;

  bool _isAnswerVisible = false;
  bool _isFinished = false;
  bool _isLoading = true;
  String? _error;

  int _allowedNew = 0;
  int _allowedReviews = 0;

  final Set<int> _sessionNewCardIds = {};
  final Set<int> _sessionReviewCardIds = {};

  StudyViewModel(DeckEntity deck, this._deckUsecase) : _deck = deck {
    _initializeStudySession();
  }

  DeckEntity get deck => _deck;
  bool get deckIsEmpty => _deck.cards.every((c) => c.isDeleted);

  /// Starts an empty deck's session with the cards just added to it.
  void cardsAdded(DeckEntity deck) {
    _deck = deck;
    _rebuildQueue();
    _totalSessionCards = max(
      _totalSessionCards,
      _completedCount + _queue.length,
    );
    _isFinished = _queue.isEmpty;
    notifyListeners();
  }

  List<CardEntity> get dueCards => _queue;
  CardEntity? get currentCard => _queue.isNotEmpty ? _queue.first : null;
  int get currentIndex => _completedCount;
  int get totalCards => _totalSessionCards;
  bool get isAnswerVisible => _isAnswerVisible;
  bool get isFinished => _isFinished;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get progress =>
      _totalSessionCards == 0 ? 1.0 : _completedCount / _totalSessionCards;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<void> _initializeStudySession() async {
    _setLoading(true);
    _clearError();

    try {
      final now = DateTime.now();
      _allowedNew = deck.newCardsLeftToday(now);
      _allowedReviews = deck.reviewsLeftToday(now);

      _rebuildQueue();

      _totalSessionCards = _queue.length;

      if (_queue.isEmpty) {
        _isFinished = true;
      }
    } catch (e) {
      _setError(l10n.failedInitStudy);
      _isFinished = true;
    } finally {
      _setLoading(false);
    }
  }

  /// Due missed cards first, then reviews mixed with new ones, then the rest.
  void _rebuildQueue() {
    final now = DateTime.now();
    final learning = <CardEntity>[];
    final waiting = <CardEntity>[];
    final reviews = <CardEntity>[];
    final newCards = <CardEntity>[];

    for (final card in deck.cards) {
      if (card.isDeleted) continue;
      final due = card.nextReviewDate;
      if (card.isNewCard || due == null) {
        newCards.add(card);
      } else if (!card.isLearning) {
        if (!due.isAfter(now)) reviews.add(card);
      } else if (!due.isAfter(now)) {
        learning.add(card);
      } else if (due.isBefore(now.add(_learnAhead))) {
        waiting.add(card);
      }
    }

    int byDue(CardEntity a, CardEntity b) =>
        a.nextReviewDate!.compareTo(b.nextReviewDate!);
    learning.sort(byDue);
    reviews.sort(byDue);
    waiting.sort(byDue);

    final newLeft = max(0, _allowedNew - _sessionNewCardIds.length);
    final reviewsLeft = max(0, _allowedReviews - _sessionReviewCardIds.length);
    _queue = [
      ...learning,
      ..._spread(
        newCards.take(newLeft).toList(),
        among: reviews.take(reviewsLeft).toList(),
      ),
      ...waiting,
    ];
  }

  static List<CardEntity> _spread(
    List<CardEntity> newCards, {
    required List<CardEntity> among,
  }) {
    final mixed = <CardEntity>[];
    var r = 0;
    for (var i = 0; i < newCards.length; i++) {
      final until = (i + 1) * among.length ~/ (newCards.length + 1);
      while (r < until) {
        mixed.add(among[r++]);
      }
      mixed.add(newCards[i]);
    }
    mixed.addAll(among.skip(r));
    return mixed;
  }

  void showAnswer() {
    _isAnswerVisible = true;
    notifyListeners();
  }

  Future<void> rateCard(StudyRating rating) async {
    if (currentCard == null) return;

    final card = currentCard!;

    if (card.isNewCard || card.nextReviewDate == null) {
      _sessionNewCardIds.add(card.id);
    } else if (!card.isLearning) {
      _sessionReviewCardIds.add(card.id);
    }

    try {
      final updatedCard = SRSService.calculateNextReview(card, rating);
      updatedCard.lastModified = DateTime.now();
      await _deckUsecase.executeUpdateCard(updatedCard);
    } catch (e) {
      _setError(l10n.failedSaveRating);
      return;
    }

    _isAnswerVisible = false;

    // A card still being learned comes back later in the session.
    if (!card.isLearning) {
      _completedCount++;
    }

    _rebuildQueue();

    if (_totalSessionCards < _completedCount + _queue.length) {
      _totalSessionCards = _completedCount + _queue.length;
    }

    if (_queue.isEmpty) {
      _isFinished = true;
    }

    notifyListeners();
  }
}
