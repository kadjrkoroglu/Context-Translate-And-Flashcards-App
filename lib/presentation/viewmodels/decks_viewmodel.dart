import 'package:flutter/material.dart';
import 'package:translate_app/data/models/deck_model.dart';
import 'package:translate_app/data/repositories/deck_repository.dart';
import 'package:translate_app/data/models/card_model.dart';

class DecksViewModel extends ChangeNotifier {
  final DeckRepository _repository;

  List<DeckItem> _decks = [];
  bool _isLoading = false;

  List<DeckItem> get decks => _decks;
  bool get isLoading => _isLoading;

  DecksViewModel(this._repository) {
    loadDecks();
  }

  Future<void> loadDecks() async {
    _isLoading = true;
    notifyListeners();

    _decks = await _repository.getAllDecks();

    for (var deck in _decks) {
      await deck.cards.load();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDeck(String name) async {
    final now = DateTime.now();
    final newDeck = DeckItem()
      ..syncId =
          '${now.millisecondsSinceEpoch.toRadixString(36)}_${now.microsecondsSinceEpoch.toRadixString(36)}'
      ..name = name
      ..createdAt = now
      ..lastModified = now
      ..orderIndex = _decks.length + 1;

    await _repository.saveDeck(newDeck);
    await loadDecks();
  }

  Future<void> deleteDeck(int id) async {
    await _repository.deleteDeck(id);
    await loadDecks();
  }

  Future<void> addCard(int deckId, String word, String translation) async {
    final now = DateTime.now();
    final newCard = CardItem()
      ..syncId =
          '${now.millisecondsSinceEpoch.toRadixString(36)}_${now.microsecondsSinceEpoch.toRadixString(36)}'
      ..word = word
      ..translation = translation
      ..createdAt = now
      ..lastModified = now;

    await _repository.addCardToDeck(deckId, newCard);
    await loadDecks();
  }

  Future<void> deleteMultipleCards(List<int> cardIds) async {
    await _repository.deleteCards(cardIds);
    await loadDecks();
  }

  int getStudyCount(DeckItem deck) {
    final now = DateTime.now();
    return deck.cards.where((card) {
      if (card.isDeleted) return false;
      if (card.nextReviewDate == null) return true;
      return card.nextReviewDate!.isBefore(now) ||
          card.nextReviewDate!.isAtSameMomentAs(now);
    }).length;
  }

  Map<String, int> getCardCountsByStatus(DeckItem deck) {
    final now = DateTime.now();

    int newCount = 0;
    int againCount = 0;
    int hardCount = 0;
    int goodCount = 0;
    int easyCount = 0;

    for (var card in deck.cards) {
      if (card.isDeleted) continue;
      if (card.nextReviewDate == null) {
        // Newly added cards
        newCount++;
      } else if (card.nextReviewDate!.isBefore(now) ||
          card.nextReviewDate!.isAtSameMomentAs(now)) {
        // Due for review - check by last rating
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

  Future<void> updateDeckLimits(
    int deckId,
    int newCardsLimit,
    int reviewsLimit,
  ) async {
    await _repository.updateDeckLimits(deckId, newCardsLimit, reviewsLimit);
    await loadDecks();
  }
}
