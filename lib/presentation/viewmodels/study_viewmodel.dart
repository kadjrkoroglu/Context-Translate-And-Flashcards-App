import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import '../../data/services/srs_service.dart';

class StudyViewModel extends ChangeNotifier {
  final DeckUsecase _deckUsecase;
  final DeckEntity deck;

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

  StudyViewModel(this.deck, this._deckUsecase) {
    _initializeStudySession();
  }

  List<CardEntity> get dueCards => _queue;
  CardEntity? get currentCard => _queue.isNotEmpty ? _queue.first : null;
  int get currentIndex => _completedCount;
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
      final allCards = deck.cards.where((c) => !c.isDeleted).toList();

      int todayNewStudied = 0;
      int todayReviewsStudied = 0;

      for (var card in allCards) {
        if (card.lastStudiedDate != null &&
            card.lastStudiedDate!.year == now.year &&
            card.lastStudiedDate!.month == now.month &&
            card.lastStudiedDate!.day == now.day) {
          if (card.repetitions == 0) {
            todayNewStudied++;
          } else {
            todayReviewsStudied++;
          }
        }
      }

      _allowedNew = (deck.newCardsLimit - todayNewStudied).clamp(
        0,
        deck.newCardsLimit,
      );
      _allowedReviews = (deck.reviewsLimit - todayReviewsStudied).clamp(
        0,
        deck.reviewsLimit,
      );

      _rebuildQueue();

      _totalSessionCards = _queue.length;

      if (_queue.isEmpty) {
        _isFinished = true;
      }
    } catch (e) {
      _setError('Failed to initialize study session');
      _isFinished = true;
    } finally {
      _setLoading(false);
    }
  }

  void _rebuildQueue() {
    final now = DateTime.now();
    final allCards = deck.cards.where((c) => !c.isDeleted).toList();

    List<CardEntity> newCards = [];
    List<CardEntity> againCards = [];
    List<CardEntity> reviewCards = [];

    for (var card in allCards) {
      if (card.nextReviewDate == null) {
        if (_sessionNewCardIds.length < _allowedNew ||
            _sessionNewCardIds.contains(card.id)) {
          newCards.add(card);
        }
      } else if (card.nextReviewDate!.isBefore(now) ||
          card.nextReviewDate!.isAtSameMomentAs(now)) {
        if (card.repetitions == 0 &&
            card.lastRatingIndex == 0 &&
            !card.isNewCard) {
          againCards.add(card);
        } else {
          if (_sessionReviewCardIds.length < _allowedReviews ||
              _sessionReviewCardIds.contains(card.id)) {
            reviewCards.add(card);
          }
        }
      }
    }

    reviewCards.sort((a, b) => a.nextReviewDate!.compareTo(b.nextReviewDate!));

    _queue = [];
    int newIdx = 0;
    int againIdx = 0;

    while (newIdx < newCards.length || againIdx < againCards.length) {
      for (int i = 0; i < 2 && newIdx < newCards.length; i++, newIdx++) {
        _queue.add(newCards[newIdx]);
      }
      if (againIdx < againCards.length) {
        _queue.add(againCards[againIdx]);
        againIdx++;
      }
    }

    _queue.addAll(reviewCards);
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
    } else if (card.repetitions > 0) {
      _sessionReviewCardIds.add(card.id);
    }

    try {
      final updatedCard = SRSService.calculateNextReview(card, rating);
      updatedCard.lastModified = DateTime.now();
      await _deckUsecase.executeUpdateCard(updatedCard);
    } catch (e) {
      _setError('Failed to save rating');
      return;
    }

    _isAnswerVisible = false;

    if (rating != StudyRating.again) {
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
