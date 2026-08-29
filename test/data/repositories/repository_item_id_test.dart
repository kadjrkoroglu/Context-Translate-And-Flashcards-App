import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:translate_app/data/models/card_model.dart';
import 'package:translate_app/data/models/deck_model.dart';
import 'package:translate_app/data/models/favorite_word_model.dart';
import 'package:translate_app/data/models/history_model.dart';
import 'package:translate_app/data/repositories/deck_repository_impl.dart';
import 'package:translate_app/data/repositories/favorite_repository_impl.dart';
import 'package:translate_app/data/repositories/history_repository_impl.dart';
import 'package:translate_app/data/services/local_storage_service.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/entities/favorite_word_entity.dart';
import 'package:translate_app/domain/entities/history_item_entity.dart';

class FakeLocalStorageService extends Fake implements LocalStorageService {
  DeckItem? savedDeck;
  CardItem? addedCard;
  CardItem? updatedCard;
  FavoriteWord? addedFavorite;
  HistoryItem? addedHistory;

  @override
  Future<void> saveDeck(DeckItem deck) async {
    savedDeck = deck;
  }

  @override
  Future<void> addCardToDeck(int deckId, CardItem card) async {
    addedCard = card;
  }

  @override
  Future<void> updateCard(CardItem card) async {
    updatedCard = card;
  }

  @override
  Future<void> addFavorite(FavoriteWord item) async {
    addedFavorite = item;
  }

  @override
  Future<void> addHistory(HistoryItem item) async {
    addedHistory = item;
  }

  @override
  Future<List<DeckItem>> getAllDecks() async => [];
}

void main() {
  late FakeLocalStorageService fakeStorage;

  setUp(() {
    fakeStorage = FakeLocalStorageService();
  });

  group('new items must not be persisted with id 0', () {
    test('saveDeck passes Isar.autoIncrement for a brand-new deck', () async {
      final repo = DeckRepositoryImpl(fakeStorage, currentUserId: () => null);
      final newDeck = DeckEntity(
        id: 0,
        syncId: 'sync-new-1',
        name: 'New Deck',
        createdAt: DateTime(2025),
        lastModified: DateTime(2025),
      );

      await repo.saveDeck(newDeck);

      expect(fakeStorage.savedDeck, isNotNull);
      expect(fakeStorage.savedDeck!.id, isNot(0));
      expect(fakeStorage.savedDeck!.id, Isar.autoIncrement);
      expect(fakeStorage.savedDeck!.syncId, 'sync-new-1');
    });

    test('saveDeck preserves the id of an existing deck', () async {
      final repo = DeckRepositoryImpl(fakeStorage, currentUserId: () => null);
      final existingDeck = DeckEntity(
        id: 5,
        syncId: 'sync-existing-1',
        name: 'Existing Deck',
        createdAt: DateTime(2025),
        lastModified: DateTime(2025),
      );

      await repo.saveDeck(existingDeck);

      expect(fakeStorage.savedDeck!.id, 5);
    });

    test(
      'addCardToDeck passes Isar.autoIncrement for a brand-new card',
      () async {
        final repo = DeckRepositoryImpl(fakeStorage, currentUserId: () => null);
        final newCard = CardEntity(
          id: 0,
          syncId: 'sync-card-new',
          word: 'hello',
          translation: 'merhaba',
          createdAt: DateTime(2025),
          lastModified: DateTime(2025),
        );

        await repo.addCardToDeck(1, newCard);

        expect(fakeStorage.addedCard, isNotNull);
        expect(fakeStorage.addedCard!.id, isNot(0));
        expect(fakeStorage.addedCard!.id, Isar.autoIncrement);
      },
    );

    test('updateCard preserves the id of an existing card', () async {
      final repo = DeckRepositoryImpl(fakeStorage, currentUserId: () => null);
      final existingCard = CardEntity(
        id: 7,
        syncId: 'sync-card-existing',
        word: 'world',
        translation: 'dünya',
        createdAt: DateTime(2025),
        lastModified: DateTime(2025),
      );

      await repo.updateCard(existingCard);

      expect(fakeStorage.updatedCard!.id, 7);
    });

    test('addFavorite passes Isar.autoIncrement for a new favorite', () async {
      final repo = FavoriteRepositoryImpl(
        fakeStorage,
        currentUserId: () => null,
      );
      final favorite = FavoriteWordEntity(
        id: 0,
        syncId: 'sync-fav-new',
        word: 'hello',
        translation: 'merhaba',
        createdAt: DateTime(2025),
        lastModified: DateTime(2025),
      );

      await repo.addFavorite(favorite);

      expect(fakeStorage.addedFavorite, isNotNull);
      expect(fakeStorage.addedFavorite!.id, isNot(0));
      expect(fakeStorage.addedFavorite!.id, Isar.autoIncrement);
    });

    test(
      'addHistory passes Isar.autoIncrement for a new history item',
      () async {
        final repo = HistoryRepositoryImpl(
          fakeStorage,
          currentUserId: () => null,
        );
        final item = HistoryItemEntity(
          id: 0,
          syncId: 'sync-history-new',
          word: 'hello',
          translation: 'merhaba',
          createdAt: DateTime(2025),
          lastModified: DateTime(2025),
        );

        await repo.addHistory(item);

        expect(fakeStorage.addedHistory, isNotNull);
        expect(fakeStorage.addedHistory!.id, isNot(0));
        expect(fakeStorage.addedHistory!.id, Isar.autoIncrement);
      },
    );
  });
}
