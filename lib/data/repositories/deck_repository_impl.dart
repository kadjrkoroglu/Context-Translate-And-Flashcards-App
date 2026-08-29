import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/repositories/deck_repository.dart';
import '../models/deck_model.dart';
import '../models/card_model.dart';
import '../services/local_storage_service.dart';

class DeckRepositoryImpl implements DeckRepository {
  final LocalStorageService _local;
  // Test-only seam: lets unit tests run without Firebase.
  final String? Function() _currentUserIdProvider;

  DeckRepositoryImpl(this._local, {String? Function()? currentUserId})
    : _currentUserIdProvider = currentUserId ?? _defaultCurrentUserId;

  static String? _defaultCurrentUserId() =>
      FirebaseAuth.instance.currentUser?.uid;

  String? get currentUserId => _currentUserIdProvider();

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
                (d.userId == currentUserId || d.userId == null) && !d.isDeleted,
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

    // Local write only; the profile "Sync Now" button pushes to the cloud.
    deck.isSynced = false;
    await _local.saveDeck(deck);
  }

  @override
  Future<void> deleteDeck(int id) async {
    final decks = await _local.getAllDecks();
    final deck = decks.where((element) => element.id == id).firstOrNull;

    if (deck != null) {
      // Soft delete: mark as deleted, update timestamp
      deck.isDeleted = true;
      // Keep it flagged so the pending delete survives an app restart.
      deck.isSynced = false;
      deck.lastModified = DateTime.now();
      await _local.saveDeck(deck);
    }
  }

  @override
  Future<void> addCardToDeck(int deckId, CardEntity card) async {
    final cardItem = _toCardItem(card);
    cardItem.userId = currentUserId;
    cardItem.isSynced = false;
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

    // Local write only; the profile "Sync Now" button pushes to the cloud.
    await _local.addCardToDeck(deckId, cardItem);
  }

  @override
  Future<void> deleteCards(List<int> cardIds) async {
    // Soft delete cards
    for (final cardId in cardIds) {
      final card = await _local.getCardById(cardId);
      if (card != null) {
        card.isDeleted = true;
        // Keep it flagged so the pending delete survives an app restart.
        card.isSynced = false;
        card.lastModified = DateTime.now();
        await _local.updateCard(card);
      }
    }
  }

  @override
  Future<void> updateCard(CardEntity card) async {
    final cardItem = _toCardItem(card);
    cardItem.userId = currentUserId;
    cardItem.isSynced = false;
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
    final item = DeckItem();
    // id 0 = new item; keep autoIncrement to avoid overwriting row 0.
    if (d.id != 0) {
      item.id = d.id;
    }
    item
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
    final item = CardItem();
    // Same as _toDeckItem: id 0 = new item -> autoIncrement.
    if (c.id != 0) {
      item.id = c.id;
    }
    return item
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
