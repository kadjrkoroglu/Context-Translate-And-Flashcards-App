import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class DeckRepository {
  final LocalStorageService _local;
  final FirestoreService _firestore;

  DeckRepository(this._local, this._firestore);

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String get _collection =>
      currentUserId != null ? 'users/$currentUserId/decks' : '';

  Future<List<DeckItem>> getAllDecks() async {
    final allDecks = await _local.getAllDecks();
    if (currentUserId == null) {
      // Logged out: show all non-deleted decks so data persists visually
      return allDecks.where((d) => !d.isDeleted).toList();
    }
    return allDecks
        .where(
          (d) =>
              (d.userId == currentUserId || d.userId == null) && !d.isDeleted,
        )
        .toList();
  }

  Future<void> saveDeck(DeckItem deck) async {
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

  Future<void> addCardToDeck(int deckId, CardItem card) async {
    card.userId = currentUserId;
    card.lastModified = DateTime.now();

    if (card.syncId.isEmpty) {
      card.syncId = _generateSyncId();
    }

    // Find deck to set deckSyncId
    final decks = await _local.getAllDecks();
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    if (deck != null) {
      card.deckSyncId = deck.syncId;
    }

    await _local.addCardToDeck(deckId, card);

    if (deck != null && deck.remoteId != null && currentUserId != null) {
      try {
        final collectionDir = _collection;
        if (collectionDir.isEmpty) return;

        final cardsCollection = '$collectionDir/${deck.remoteId}/cards';
        if (card.remoteId != null) {
          await _firestore.setDocument(
            '$cardsCollection/${card.remoteId}',
            card.toMap(),
          );
        } else {
          final remoteId = await _firestore.addDocument(
            cardsCollection,
            card.toMap(),
          );
          card.remoteId = remoteId;
        }
        card.isSynced = true;
        await _local.updateCard(card);
      } catch (e) {
        debugPrint('Card add sync failed: $e');
      }
    }
  }

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

  Future<void> updateCard(CardItem card) async {
    card.userId = currentUserId;
    card.lastModified = DateTime.now();
    await _local.updateCard(card);
  }

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
      await saveDeck(deck);
    }
  }

  String _generateSyncId() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch.toRadixString(36);
    return '${now.millisecondsSinceEpoch.toRadixString(36)}_$random';
  }
}
