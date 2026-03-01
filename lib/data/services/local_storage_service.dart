import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/favorite_word_model.dart';
import '../models/history_model.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';

class LocalStorageService {
  late Isar isar;

  Future<void> clearAllData() async {
    await isar.writeTxn(() async {
      await isar.favoriteWords.clear();
      await isar.historyItems.clear();
      await isar.cardItems.clear();
      await isar.deckItems.clear();
    });
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([
      FavoriteWordSchema,
      HistoryItemSchema,
      CardItemSchema,
      DeckItemSchema,
    ], directory: dir.path);
  }

  Future<void> addFavorite(FavoriteWord favorite) async {
    await isar.writeTxn(() async {
      await isar.favoriteWords.put(favorite);
    });
  }

  Future<List<FavoriteWord>> getAllFavorites() async {
    return await isar.favoriteWords.where().findAll();
  }

  Future<void> deleteFavorite(int id) async {
    await isar.writeTxn(() async {
      await isar.favoriteWords.delete(id);
    });
  }

  Future<void> addHistory(HistoryItem item) async {
    await isar.writeTxn(() async {
      await isar.historyItems.put(item);
    });
  }

  Future<List<HistoryItem>> getAllHistory() async {
    // Sorted by newest first
    return await isar.historyItems.where().sortByCreatedAtDesc().findAll();
  }

  Future<void> deleteHistoryItem(int id) async {
    await isar.writeTxn(() async {
      await isar.historyItems.delete(id);
    });
  }

  Future<void> clearHistory() async {
    await isar.writeTxn(() async {
      await isar.historyItems.clear();
    });
  }

  Future<List<DeckItem>> getAllDecks() async {
    return await isar.deckItems.where().sortByCreatedAt().findAll();
  }

  Future<void> saveDeck(DeckItem deck) async {
    await isar.writeTxn(() async {
      await isar.deckItems.put(deck);
    });
  }

  Future<void> deleteDeck(int id) async {
    final deck = await isar.deckItems.get(id);
    if (deck != null) {
      // Implicit read transaction outside the writeTxn
      final cardsToDelete = deck.cards.toList();

      await isar.writeTxn(() async {
        for (final card in cardsToDelete) {
          await isar.cardItems.delete(card.id);
        }
        await isar.deckItems.delete(id);
      });
    }
  }

  Future<void> addCardToDeck(int deckId, CardItem card) async {
    await isar.writeTxn(() async {
      await isar.cardItems.put(card);
      final deck = await isar.deckItems.get(deckId);
      if (deck != null) {
        deck.cards.add(card);
        await deck.cards.save();
      }
    });
  }

  Future<void> deleteCards(List<int> cardIds) async {
    await isar.writeTxn(() async {
      await isar.cardItems.deleteAll(cardIds);
    });
  }

  Future<void> updateCard(CardItem card) async {
    await isar.writeTxn(() async {
      await isar.cardItems.put(card);
    });
  }

  Future<CardItem?> getCardById(int id) async {
    return await isar.cardItems.get(id);
  }

  Future<void> updateDeckLimits(
    int deckId,
    int newCardsLimit,
    int reviewsLimit,
  ) async {
    await isar.writeTxn(() async {
      final deck = await isar.deckItems.get(deckId);
      if (deck != null) {
        deck.newCardsLimit = newCardsLimit;
        deck.reviewsLimit = reviewsLimit;
        await isar.deckItems.put(deck);
      }
    });
  }
}
