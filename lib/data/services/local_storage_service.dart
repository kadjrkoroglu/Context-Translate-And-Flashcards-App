import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import '../models/favorite_word_model.dart';
import '../models/history_model.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';

class LocalStorageService {
  late Isar isar;

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open([
        FavoriteWordSchema,
        HistoryItemSchema,
        CardItemSchema,
        DeckItemSchema,
      ], directory: dir.path);
    } catch (e) {
      throw StorageException('Failed to initialize database', details: e.toString());
    }
  }

  Future<void> clearAllData() async {
    try {
      await isar.writeTxn(() async {
        await isar.favoriteWords.clear();
        await isar.historyItems.clear();
        await isar.cardItems.clear();
        await isar.deckItems.clear();
      });
    } catch (e) {
      throw StorageException('Failed to clear data', details: e.toString());
    }
  }

  Future<void> addFavorite(FavoriteWord favorite) async {
    try {
      await isar.writeTxn(() async {
        await isar.favoriteWords.put(favorite);
      });
    } catch (e) {
      throw StorageException('Failed to add favorite', details: e.toString());
    }
  }

  Future<List<FavoriteWord>> getAllFavorites() async {
    try {
      return await isar.favoriteWords.where().sortByCreatedAtDesc().findAll();
    } catch (e) {
      throw StorageException('Failed to get favorites', details: e.toString());
    }
  }

  Future<void> deleteFavorite(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.favoriteWords.delete(id);
      });
    } catch (e) {
      throw StorageException('Failed to delete favorite', details: e.toString());
    }
  }

  Future<void> addHistory(HistoryItem item) async {
    try {
      await isar.writeTxn(() async {
        await isar.historyItems.put(item);
      });
    } catch (e) {
      throw StorageException('Failed to save history', details: e.toString());
    }
  }

  Future<List<HistoryItem>> getAllHistory() async {
    try {
      return await isar.historyItems.where().sortByCreatedAtDesc().findAll();
    } catch (e) {
      throw StorageException('Failed to get history', details: e.toString());
    }
  }

  Future<void> deleteHistoryItem(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.historyItems.delete(id);
      });
    } catch (e) {
      throw StorageException('Failed to delete history item', details: e.toString());
    }
  }

  Future<void> clearHistory() async {
    try {
      await isar.writeTxn(() async {
        await isar.historyItems.clear();
      });
    } catch (e) {
      throw StorageException('Failed to clear history', details: e.toString());
    }
  }

  Future<List<DeckItem>> getAllDecks() async {
    try {
      return await isar.deckItems.where().sortByCreatedAt().findAll();
    } catch (e) {
      throw StorageException('Failed to get decks', details: e.toString());
    }
  }

  Future<void> saveDeck(DeckItem deck) async {
    try {
      await isar.writeTxn(() async {
        await isar.deckItems.put(deck);
      });
    } catch (e) {
      throw StorageException('Failed to save deck', details: e.toString());
    }
  }

  Future<void> deleteDeck(int id) async {
    try {
      final deck = await isar.deckItems.get(id);
      if (deck != null) {
        final cardsToDelete = deck.cards.toList();

        await isar.writeTxn(() async {
          for (final card in cardsToDelete) {
            await isar.cardItems.delete(card.id);
          }
          await isar.deckItems.delete(id);
        });
      }
    } catch (e) {
      throw StorageException('Failed to delete deck', details: e.toString());
    }
  }

  Future<void> addCardToDeck(int deckId, CardItem card) async {
    try {
      await isar.writeTxn(() async {
        await isar.cardItems.put(card);
        final deck = await isar.deckItems.get(deckId);
        if (deck != null) {
          deck.cards.add(card);
          await deck.cards.save();
        }
      });
    } catch (e) {
      throw StorageException('Failed to add card', details: e.toString());
    }
  }

  Future<void> deleteCards(List<int> cardIds) async {
    try {
      await isar.writeTxn(() async {
        await isar.cardItems.deleteAll(cardIds);
      });
    } catch (e) {
      throw StorageException('Failed to delete cards', details: e.toString());
    }
  }

  Future<void> updateCard(CardItem card) async {
    try {
      await isar.writeTxn(() async {
        await isar.cardItems.put(card);
      });
    } catch (e) {
      throw StorageException('Failed to update card', details: e.toString());
    }
  }

  Future<CardItem?> getCardById(int id) async {
    try {
      return await isar.cardItems.get(id);
    } catch (e) {
      throw StorageException('Failed to get card', details: e.toString());
    }
  }

  Future<void> updateDeckLimits(
    int deckId,
    int newCardsLimit,
    int reviewsLimit,
  ) async {
    try {
      await isar.writeTxn(() async {
        final deck = await isar.deckItems.get(deckId);
        if (deck != null) {
          deck.newCardsLimit = newCardsLimit;
          deck.reviewsLimit = reviewsLimit;
          await isar.deckItems.put(deck);
        }
      });
    } catch (e) {
      throw StorageException('Failed to update deck limits', details: e.toString());
    }
  }
}
