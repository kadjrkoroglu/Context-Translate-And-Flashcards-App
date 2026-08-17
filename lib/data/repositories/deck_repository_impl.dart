import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/repositories/deck_repository.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class DeckRepositoryImpl implements DeckRepository {
  final LocalStorageService _local;
  final FirestoreService _firestore;

  DeckRepositoryImpl(this._local, this._firestore);

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String get _collection =>
      currentUserId != null ? 'users/$currentUserId/decks' : '';

  @override
  Future<List<DeckEntity>> getAllDecks() async {
    final allDecks = await _local.getAllDecks();
    final List<DeckItem> filtered;
    if (currentUserId == null) {
      // Logged out: show all non-deleted decks so data persists visually
      filtered = allDecks.where((d) => !d.isDeleted).toList();
    } else {
      filtered = allDecks
          .where(
            (d) =>
                (d.userId == currentUserId || d.userId == null) &&
                !d.isDeleted,
          )
          .toList();
    }

    final decks = <DeckEntity>[];
    for (final d in filtered) {
      await d.cards.load();
      decks.add(_toDeck(d));
    }
    return decks;
  }

  @override
  Future<void> saveDeck(DeckEntity deck) async {
    await _saveDeckItem(_toDeckItem(deck));
  }

  Future<void> _saveDeckItem(DeckItem deck) async {
    deck.userId = currentUserId;
    deck.lastModified = DateTime.now();

    // Assign syncId if missing
    if (deck.syncId.isEmpty) {
      deck.syncId = _generateSyncId();
    }

    // Save locally
    await _local.saveDeck(deck);

    // Push to firebase if logged in
    if (currentUserId != null) {
      try {
        final collectionDir = _collection;
        if (collectionDir.isEmpty) return;

        if (deck.remoteId != null) {
          await _firestore.setDocument(
            '$collectionDir/${deck.remoteId}',
            deck.toMap(),
          );
          deck.isSynced = true;
          await _local.saveDeck(deck);
        } else {
          final remoteId = await _firestore.addDocument(
            collectionDir,
            deck.toMap(),
          );
          deck.remoteId = remoteId;
          deck.isSynced = true;
          await _local.saveDeck(deck);
        }
      } catch (e) {
        debugPrint('Deck save sync failed: $e');
      }
    }
  }

  @override
  Future<void> deleteDeck(int id) async {
    final decks = await _local.getAllDecks();
    final deck = decks.where((element) => element.id == id).firstOrNull;

    if (deck != null) {
      // Soft delete: mark as deleted, update timestamp
      deck.isDeleted = true;
      deck.lastModified = DateTime.now();
      await _local.saveDeck(deck);

      if (deck.remoteId != null && currentUserId != null) {
        try {
          final collectionDir = _collection;
          if (collectionDir.isEmpty) return;
          await _firestore.setDocument(
            '$collectionDir/${deck.remoteId}',
            deck.toMap(),
          );
        } catch (e) {
          debugPrint('Deck soft-delete sync failed: $e');
        }
      }
    }
  }

  @override
  Future<void> addCardToDeck(int deckId, CardEntity card) async {
    final cardItem = _toCardItem(card);
    cardItem.userId = currentUserId;
    cardItem.lastModified = DateTime.now();

    if (cardItem.syncId.isEmpty) {
      cardItem.syncId = _generateSyncId();
    }

    // Find deck to set deckSyncId
    final decks = await _local.getAllDecks();
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    if (deck != null) {
      cardItem.deckSyncId = deck.syncId;
    }

    await _local.addCardToDeck(deckId, cardItem);

    if (deck != null && deck.remoteId != null && currentUserId != null) {
      try {
        final collectionDir = _collection;
        if (collectionDir.isEmpty) return;

        final cardsCollection = '$collectionDir/${deck.remoteId}/cards';
        if (cardItem.remoteId != null) {
          await _firestore.setDocument(
            '$cardsCollection/${cardItem.remoteId}',
            cardItem.toMap(),
          );
        } else {
          final remoteId = await _firestore.addDocument(
            cardsCollection,
            cardItem.toMap(),
          );
          cardItem.remoteId = remoteId;
        }
        cardItem.isSynced = true;
        await _local.updateCard(cardItem);
      } catch (e) {
        debugPrint('Card add sync failed: $e');
      }
    }
  }

  @override
  Future<void> deleteCards(List<int> cardIds) async {
    // Soft delete cards
    for (final cardId in cardIds) {
      final card = await _local.getCardById(cardId);
      if (card != null) {
        card.isDeleted = true;
        card.lastModified = DateTime.now();
        await _local.updateCard(card);
      }
    }
  }

  @override
  Future<void> updateCard(CardEntity card) async {
    final cardItem = _toCardItem(card);
    cardItem.userId = currentUserId;
    cardItem.lastModified = DateTime.now();
    await _local.updateCard(cardItem);
  }

  @override
  Future<void> updateDeckLimits(
    int deckId,
    int newCardsLimit,
    int reviewsLimit,
  ) async {
    await _local.updateDeckLimits(deckId, newCardsLimit, reviewsLimit);

    final decks = await _local.getAllDecks();
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    if (deck != null) {
      deck.lastModified = DateTime.now();
      await _saveDeckItem(deck);
    }
  }

  DeckEntity _toDeck(DeckItem d) {
    return DeckEntity(
      id: d.id,
      syncId: d.syncId,
      name: d.name,
      createdAt: d.createdAt,
      lastModified: d.lastModified,
      newCardsLimit: d.newCardsLimit,
      reviewsLimit: d.reviewsLimit,
      cards: d.cards.map(_toCard).toList(),
      orderIndex: d.orderIndex,
      userId: d.userId,
      remoteId: d.remoteId,
      isSynced: d.isSynced,
      isDeleted: d.isDeleted,
    );
  }

  DeckItem _toDeckItem(DeckEntity d) {
    final item = DeckItem()
      ..id = d.id
      ..syncId = d.syncId
      ..name = d.name
      ..createdAt = d.createdAt
      ..lastModified = d.lastModified
      ..newCardsLimit = d.newCardsLimit
      ..reviewsLimit = d.reviewsLimit
      ..orderIndex = d.orderIndex
      ..userId = d.userId
      ..remoteId = d.remoteId
      ..isSynced = d.isSynced
      ..isDeleted = d.isDeleted;
    item.cards.addAll(d.cards.map(_toCardItem));
    return item;
  }

  CardEntity _toCard(CardItem c) {
    return CardEntity(
      id: c.id,
      syncId: c.syncId,
      word: c.word,
      translation: c.translation,
      createdAt: c.createdAt,
      lastModified: c.lastModified,
      nextReviewDate: c.nextReviewDate,
      easeFactor: c.easeFactor,
      interval: c.interval,
      repetitions: c.repetitions,
      isNewCard: c.isNewCard,
      lastStudiedDate: c.lastStudiedDate,
      lastRatingIndex: c.lastRatingIndex,
      userId: c.userId,
      remoteId: c.remoteId,
      isSynced: c.isSynced,
      isDeleted: c.isDeleted,
      deckSyncId: c.deckSyncId,
    );
  }

  CardItem _toCardItem(CardEntity c) {
    return CardItem()
      ..id = c.id
      ..syncId = c.syncId
      ..word = c.word
      ..translation = c.translation
      ..createdAt = c.createdAt
      ..lastModified = c.lastModified
      ..nextReviewDate = c.nextReviewDate
      ..easeFactor = c.easeFactor
      ..interval = c.interval
      ..repetitions = c.repetitions
      ..isNewCard = c.isNewCard
      ..lastStudiedDate = c.lastStudiedDate
      ..lastRatingIndex = c.lastRatingIndex
      ..userId = c.userId
      ..remoteId = c.remoteId
      ..isSynced = c.isSynced
      ..isDeleted = c.isDeleted
      ..deckSyncId = c.deckSyncId;
  }

  String _generateSyncId() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch.toRadixString(36);
    return '${now.millisecondsSinceEpoch.toRadixString(36)}_$random';
  }
}
