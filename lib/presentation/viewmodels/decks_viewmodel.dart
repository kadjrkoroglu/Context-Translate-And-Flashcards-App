import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';

class DecksViewModel extends ChangeNotifier {
  final DeckUsecase _usecase;

  List<DeckEntity> _decks = [];
  bool _isLoading = false;
  String? _error;

  List<DeckEntity> get decks => _decks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DecksViewModel(this._usecase) {
    loadDecks();
  }

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

  Future<void> loadDecks() async {
    _setLoading(true);
    _clearError();

    try {
      _decks = await _usecase.executeGetAllDecks();
    } catch (e) {
      _setError('Failed to load decks');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addDeck(String name) async {
    _clearError();
    final now = DateTime.now();
    final newDeck = DeckEntity(
      id: 0,
      syncId:
          '${now.millisecondsSinceEpoch.toRadixString(36)}_${now.microsecondsSinceEpoch.toRadixString(36)}',
      name: name,
      createdAt: now,
      lastModified: now,
      orderIndex: _decks.length + 1,
    );

    try {
      await _usecase.executeSaveDeck(newDeck);
      await loadDecks();
    } catch (e) {
      _setError('Failed to add deck');
    }
  }

  Future<void> deleteDeck(int id) async {
    _clearError();
    try {
      await _usecase.executeDeleteDeck(id);
      await loadDecks();
    } catch (e) {
      _setError('Failed to delete deck');
    }
  }

  Future<void> addCard(int deckId, String word, String translation) async {
    _clearError();
    final now = DateTime.now();
    final newCard = CardEntity(
      id: 0,
      syncId:
          '${now.millisecondsSinceEpoch.toRadixString(36)}_${now.microsecondsSinceEpoch.toRadixString(36)}',
      word: word,
      translation: translation,
      createdAt: now,
      lastModified: now,
    );

    try {
      await _usecase.executeAddCardToDeck(deckId, newCard);
      await loadDecks();
    } catch (e) {
      _setError('Failed to add card');
    }
  }

  Future<void> deleteMultipleCards(List<int> cardIds) async {
    _clearError();
    try {
      await _usecase.executeDeleteCards(cardIds);
      await loadDecks();
    } catch (e) {
      _setError('Failed to delete cards');
    }
  }

  int getStudyCount(DeckEntity deck) {
    final now = DateTime.now();
    return deck.cards.where((card) {
      if (card.isDeleted) return false;
      if (card.nextReviewDate == null) return true;
      return card.nextReviewDate!.isBefore(now) ||
          card.nextReviewDate!.isAtSameMomentAs(now);
    }).length;
  }

  int getTotalCardCount(DeckEntity deck) {
    return deck.cards.where((card) => !card.isDeleted).length;
  }

  Map<String, int> getCardCountsByStatus(DeckEntity deck) {
    final now = DateTime.now();

    int newCount = 0;
    int againCount = 0;
    int hardCount = 0;
    int goodCount = 0;
    int easyCount = 0;

    for (var card in deck.cards) {
      if (card.isDeleted) continue;
      if (card.nextReviewDate == null) {
        newCount++;
      } else if (card.nextReviewDate!.isBefore(now) ||
          card.nextReviewDate!.isAtSameMomentAs(now)) {
        switch (card.lastRatingIndex) {
          case 0:
            againCount++;
            break;
          case 1:
            hardCount++;
            break;
          case 2:
            goodCount++;
            break;
          case 3:
            easyCount++;
            break;
          default:
            againCount++;
        }
      }
    }

    return {
      'new': newCount,
      'again': againCount,
      'hard': hardCount,
      'good': goodCount,
      'easy': easyCount,
    };
  }

  Future<void> updateDeckSettings(
    int deckId,
    String newName,
    int newCardsLimit,
    int reviewsLimit,
  ) async {
    _clearError();
    try {
      final deck = _decks.firstWhere((d) => d.id == deckId);
      final name = newName.trim().isEmpty ? deck.name : newName.trim();
      final nameChanged = name != deck.name;
      final limitsChanged =
          newCardsLimit != deck.newCardsLimit ||
          reviewsLimit != deck.reviewsLimit;

      if (!nameChanged && !limitsChanged) return;

      await _usecase.executeSaveDeck(
        DeckEntity(
          id: deck.id,
          syncId: deck.syncId,
          name: name,
          createdAt: deck.createdAt,
          lastModified: deck.lastModified,
          newCardsLimit: newCardsLimit,
          reviewsLimit: reviewsLimit,
          cards: deck.cards,
          orderIndex: deck.orderIndex,
          userId: deck.userId,
          remoteId: deck.remoteId,
          isSynced: deck.isSynced,
          isDeleted: deck.isDeleted,
        ),
      );
      await loadDecks();
    } catch (e) {
      _setError('Failed to update deck settings');
    }
  }

  Future<void> updateDeckLimits(
    int deckId,
    int newCardsLimit,
    int reviewsLimit,
  ) async {
    _clearError();
    try {
      await _usecase.executeUpdateDeckLimits(
        deckId,
        newCardsLimit,
        reviewsLimit,
      );
      await loadDecks();
    } catch (e) {
      _setError('Failed to update deck limits');
    }
  }
}
