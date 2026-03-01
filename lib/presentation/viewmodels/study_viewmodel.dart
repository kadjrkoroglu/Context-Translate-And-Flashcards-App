import 'package:flutter/material.dart';
import '../../data/models/card_model.dart';
import '../../data/models/deck_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/srs_service.dart';

class StudyViewModel extends ChangeNotifier {
  final LocalStorageService _storageService;
  final DeckItem deck;

  // Study queue
  List<CardItem> _queue = [];
  // Session progress
  int _completedCount = 0;
  int _totalSessionCards = 0;

  bool _isAnswerVisible = false;
  bool _isFinished = false;
  bool _isLoading = true;

  // Deck limits tracked for the session
  int _allowedNew = 0;
  int _allowedReviews = 0;

  // Active session tracking
  final Set<int> _sessionNewCardIds = {};
  final Set<int> _sessionReviewCardIds = {};

  StudyViewModel(this._storageService, this.deck) {
    _initializeStudySession();
  }

  List<CardItem> get dueCards => _queue;
  CardItem? get currentCard => _queue.isNotEmpty ? _queue.first : null;
  int get currentIndex => _completedCount;
  bool get isAnswerVisible => _isAnswerVisible;
  bool get isFinished => _isFinished;
  bool get isLoading => _isLoading;
  double get progress =>
      _totalSessionCards == 0 ? 1.0 : _completedCount / _totalSessionCards;

  Future<void> _initializeStudySession() async {
    _isLoading = true;
    notifyListeners();

    try {
      await deck.cards.load();
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

      // Build initial queue
      _rebuildQueue();

      _totalSessionCards = _queue.length;

      if (_queue.isEmpty) {
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

  /// Rebuilds the study queue dynamically.
  void _rebuildQueue() {
    final now = DateTime.now();
    final allCards = deck.cards.where((c) => !c.isDeleted).toList();

    List<CardItem> newCards = [];
    List<CardItem> againCards =
        []; // Learning-phase: Again with expired cooldown
    List<CardItem> reviewCards = [];

    for (var card in allCards) {
      if (card.nextReviewDate == null) {
        // Brand new, never studied card
        if (_sessionNewCardIds.length < _allowedNew ||
            _sessionNewCardIds.contains(card.id)) {
          newCards.add(card);
        }
      } else if (card.nextReviewDate!.isBefore(now) ||
          card.nextReviewDate!.isAtSameMomentAs(now)) {
        // Card is due - distinguish Again (learning) from regular reviews
        if (card.repetitions == 0 &&
            card.lastRatingIndex == 0 &&
            !card.isNewCard) {
          // This is an "Again" card in learning phase (rep reset to 0, rated Again)
          againCards.add(card);
        } else {
          if (_sessionReviewCardIds.length < _allowedReviews ||
              _sessionReviewCardIds.contains(card.id)) {
            reviewCards.add(card);
          }
        }
      }
    }

    // Sort reviews by urgency (oldest due first)
    reviewCards.sort((a, b) => a.nextReviewDate!.compareTo(b.nextReviewDate!));

    // Build queue (New -> Again -> Reviews)
    _queue = [];
    int newIdx = 0;
    int againIdx = 0;

    // Interleave: every 2 new cards, insert 1 again card
    while (newIdx < newCards.length || againIdx < againCards.length) {
      // Add up to 2 new cards
      for (int i = 0; i < 2 && newIdx < newCards.length; i++, newIdx++) {
        _queue.add(newCards[newIdx]);
      }
      // Insert 1 again card if available
      if (againIdx < againCards.length) {
        _queue.add(againCards[againIdx]);
        againIdx++;
      }
    }

    // Append remaining review cards at the end
    _queue.addAll(reviewCards);
  }

  void showAnswer() {
    _isAnswerVisible = true;
    notifyListeners();
  }

  Future<void> rateCard(StudyRating rating) async {
    if (currentCard == null) return;

    final card = currentCard!;

    // Track session cards
    if (card.isNewCard || card.nextReviewDate == null) {
      _sessionNewCardIds.add(card.id);
    } else if (card.repetitions > 0) {
      _sessionReviewCardIds.add(card.id);
    }

    // Apply SRS algorithm
    final updatedCard = SRSService.calculateNextReview(card, rating);
    updatedCard.lastModified = DateTime.now();
    await _storageService.updateCard(updatedCard);

    _isAnswerVisible = false;

    // Success count
    if (rating != StudyRating.again) {
      _completedCount++;
    }

    // Reload cards from storage and rebuild queue dynamically
    await deck.cards.load();
    _rebuildQueue();

    // Update total to account for again cards that re-enter the queue
    if (_totalSessionCards < _completedCount + _queue.length) {
      _totalSessionCards = _completedCount + _queue.length;
    }

    if (_queue.isEmpty) {
      _isFinished = true;
    }

    notifyListeners();
  }
}
