import 'package:flutter/material.dart';
import '../../data/models/card_model.dart';
import '../../data/models/deck_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/srs_service.dart';

class StudyViewModel extends ChangeNotifier {
  final LocalStorageService _storageService;
  final DeckItem deck;

  List<CardItem> _dueCards = [];
  int _currentIndex = 0;
  bool _isAnswerVisible = false;
  bool _isFinished = false;
  bool _isLoading = true;

  StudyViewModel(this._storageService, this.deck) {
    _initializeStudySession();
  }

  List<CardItem> get dueCards => _dueCards;
  CardItem? get currentCard =>
      _dueCards.isNotEmpty && _currentIndex < _dueCards.length
      ? _dueCards[_currentIndex]
      : null;
  int get currentIndex => _currentIndex;
  bool get isAnswerVisible => _isAnswerVisible;
  bool get isFinished => _isFinished;
  bool get isLoading => _isLoading;
  double get progress =>
      _dueCards.isEmpty ? 1.0 : (_currentIndex + 1) / _dueCards.length;

  Future<void> _initializeStudySession() async {
    _isLoading = true;
    notifyListeners();

    try {
      await deck.cards.load();
      final now = DateTime.now();
      final allCards = deck.cards.toList();

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

      int allowedNew = (deck.newCardsLimit - todayNewStudied).clamp(
        0,
        deck.newCardsLimit,
      );
      int allowedReviews = (deck.reviewsLimit - todayReviewsStudied).clamp(
        0,
        deck.reviewsLimit,
      );

      List<CardItem> pendingNew = [];
      List<CardItem> pendingReviews = [];

      for (var card in allCards) {
        // Include new cards and cards due for review within deck limits
        if (card.nextReviewDate == null) {
          pendingNew.add(card);
        } else if (card.nextReviewDate!.isBefore(now) ||
            card.nextReviewDate!.isAtSameMomentAs(now)) {
          pendingReviews.add(card);
        }
      }

      pendingReviews.sort(
        (a, b) => a.nextReviewDate!.compareTo(b.nextReviewDate!),
      );

      _dueCards = [
        ...pendingNew.take(allowedNew),
        ...pendingReviews.take(allowedReviews),
      ];

      if (_dueCards.isEmpty) {
        _isFinished = true;
      }
    } catch (e) {
      debugPrint("Error initializing study session: $e");
      _isFinished = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void showAnswer() {
    _isAnswerVisible = true;
    notifyListeners();
  }

  Future<void> rateCard(StudyRating rating) async {
    if (currentCard == null) return;

    final updatedCard = SRSService.calculateNextReview(currentCard!, rating);
    await _storageService.updateCard(updatedCard);

    _isAnswerVisible = false;
    _currentIndex++;

    if (_currentIndex >= _dueCards.length) {
      _isFinished = true;
    }

    notifyListeners();
  }
}
