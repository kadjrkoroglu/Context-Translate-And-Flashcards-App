import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:translate_app/core/errors/app_exception.dart';import 'package:translate_app/data/models/card_model.dart';
import 'package:translate_app/data/models/deck_model.dart';
import 'package:translate_app/data/models/favorite_word_model.dart';
import 'package:translate_app/data/models/history_model.dart';
import 'package:translate_app/data/services/local_storage_service.dart';
import 'package:translate_app/data/services/firestore_service.dart';

class SyncService extends ChangeNotifier {
  final LocalStorageService _local;
  final FirestoreService _firestore;

  bool _isSyncing = false;
  String? _syncError;
  bool _hasUnsyncedChanges = false;
  bool _mutationDuringSync = false;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  bool get hasUnsyncedChanges => _hasUnsyncedChanges;

  SyncService(this._local, this._firestore) {
    _setupChangeListeners();
  }

  /// Marks local data as changed so the UI can show the "Sync Now" button.
  /// Called either from Isar watches or from [LocalStorageService.onLocalMutation].
  void markUnsynced() {
    if (_isSyncing) {
      // A change arrived while sync is running: remember it and re-evaluate
      // the real unsynced state once sync finishes.
      _mutationDuringSync = true;
      return;
    }
    if (!_hasUnsyncedChanges) {
      _hasUnsyncedChanges = true;
      notifyListeners();
    }
  }

  void _setupChangeListeners() {
    _subscriptions.add(
      _local.isar.favoriteWords.watchLazy().listen((_) => _onLocalWrite()),
    );
    _subscriptions.add(
      _local.isar.historyItems.watchLazy().listen((_) => _onLocalWrite()),
    );
    _subscriptions.add(
      _local.isar.deckItems.watchLazy().listen((_) => _onLocalWrite()),
    );
    _subscriptions.add(
      _local.isar.cardItems.watchLazy().listen((_) => _onLocalWrite()),
    );
    _local.onLocalMutation = markUnsynced;
    checkUnsyncedChanges();
  }

  void _onLocalWrite() {
    markUnsynced();
  }

  Future<void> _cleanupDuplicateDecks() async {
    final decks = await _local.getAllDecks();
    final bySyncId = <String, DeckItem>{};
    for (final d in decks) {
      if (d.syncId.isEmpty) continue;
      final existing = bySyncId[d.syncId];
      if (existing == null) {
        bySyncId[d.syncId] = d;
        continue;
      }
      // Prefer the record with a real Isar id; always keep one and drop the rest.
      DeckItem keep;
      final drop = existing.id == 0 ? existing : d;
      if (existing.id == 0 && d.id != 0) {
        keep = d;
      } else if (existing.id != 0 && d.id == 0) {
        keep = existing;
      } else {
        keep = existing;
      }
      await _local.deleteDeckItemOnly(drop.id);
      bySyncId[d.syncId] = keep;
    }
  }

  Future<bool> checkUnsyncedChanges() async {
    if (_userId == null) {
      if (_hasUnsyncedChanges) {
        _hasUnsyncedChanges = false;
        notifyListeners();
      }
      return false;
    }
    try {
      final decks = await _local.getAllDecks();
      final unsyncedDecks = decks.where((d) => (d.userId == _userId || d.userId == null) && !d.isDeleted && !d.isSynced).toList();
      if (unsyncedDecks.isNotEmpty) {
        _hasUnsyncedChanges = true;
        notifyListeners();
        return true;
      }

      final cards = await _local.isar.cardItems.where().findAll();
      final unsyncedCards = cards.where((c) => (c.userId == _userId || c.userId == null) && !c.isDeleted && !c.isSynced).toList();
      if (unsyncedCards.isNotEmpty) {
        _hasUnsyncedChanges = true;
        notifyListeners();
        return true;
      }

      final favs = await _local.getAllFavorites();
      final unsyncedFavs = favs.where((f) => (f.userId == _userId || f.userId == null) && !f.isDeleted && !f.isSynced).toList();
      if (unsyncedFavs.isNotEmpty) {
        _hasUnsyncedChanges = true;
        notifyListeners();
        return true;
      }

      final history = await _local.getAllHistory();
      final unsyncedHistory = history.where((h) => (h.userId == _userId || h.userId == null) && !h.isDeleted && !h.isSynced).toList();
      if (unsyncedHistory.isNotEmpty) {
        _hasUnsyncedChanges = true;
        notifyListeners();
        return true;
      }

      return _hasUnsyncedChanges;
    } catch (e) {
      debugPrint('SyncService: Error checking unsynced changes: $e');
      return false;
    }
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  String get _decksPath => 'users/$_userId/decks';
  String get _favoritesPath => 'users/$_userId/favorites';
  String get _historyPath => 'users/$_userId/history';
  String _cardsPath(String deckRemoteId) =>
      'users/$_userId/decks/$deckRemoteId/cards';

  String get _flashcardsPath => 'users/$_userId/flashcards';

  /// Main sync entry point — call this from the "Senkronize Et" button.
  ///
  /// Returns an error message string if the user is not logged in,
  /// otherwise returns null on success (check [syncError] for failures).
  Future<String?> syncAll() async {
    if (_userId == null) {
      _syncError = 'Please log in first';
      notifyListeners();
      return _syncError;
    }

    if (_isSyncing) return null;

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      await _cleanupDuplicateDecks();
      await Future.wait([
        _syncDecksAndCards(),
        _syncFavorites(),
        _syncHistory(),
      ]);
    } catch (e) {
      _syncError = _friendlyError(e);
    } finally {
      _isSyncing = false;
      _hasUnsyncedChanges = false;
      if (_mutationDuringSync) {
        // A change happened while syncing (e.g. delete deck, delete favorite,
        // deck settings). Re-evaluate ground truth with the local db so the
        // change is not silently lost.
        _mutationDuringSync = false;
        await checkUnsyncedChanges();
      }
      notifyListeners();
    }

    return _syncError;
  }

  String _friendlyError(Object e) {
    if (e is AppException) return e.message;
    if (e is FirebaseException) return e.message ?? 'Sync error occurred';
    return 'Sync failed. Please check your connection and try again.';
  }

  // DECKS + CARDS SYNC

  Future<void> _syncDecksAndCards() async {
    final localDecks = await _local.getAllDecks();
    final userLocalDecks = localDecks
        .where((d) => d.userId == _userId || d.userId == null)
        .toList();

    final remoteDecksData = await _firestore.getCollection(_decksPath);

    final localBySyncId = <String, DeckItem>{};
    for (final d in userLocalDecks) {
      localBySyncId[d.syncId] = d;
    }

    final remoteBySyncId = <String, Map<String, dynamic>>{};
    for (final m in remoteDecksData) {
      final sid = m['syncId'] as String? ?? m['remoteId'] as String? ?? '';
      if (sid.isNotEmpty) remoteBySyncId[sid] = m;
    }

    final allSyncIds = <String>{...localBySyncId.keys, ...remoteBySyncId.keys};

    final batchOps = <Map<String, dynamic>>[];
    final cardSyncFutures = <Future<void>>[];

    for (final syncId in allSyncIds) {
      final localDeck = localBySyncId[syncId];
      final remoteMap = remoteBySyncId[syncId];

      if (localDeck != null && remoteMap != null) {
        final localMod = localDeck.lastModified;
        final remoteMod = remoteMap['lastModified'] != null
            ? DateTime.parse(remoteMap['lastModified'])
            : DateTime.parse(remoteMap['createdAt']);

        final remoteId = remoteMap['remoteId'] as String;

        if (localDeck.isDeleted || (remoteMap['isDeleted'] == true)) {
          // Soft-deleted on either side → propagate deletion
          final now = DateTime.now();
          localDeck.isDeleted = true;
          localDeck.lastModified = now;
          localDeck.remoteId = remoteId;
          localDeck.userId = _userId;
          localDeck.isSynced = true;
          await _local.saveDeck(localDeck);

          final deckData = localDeck.toMap();
          deckData['lastModified'] = now.toIso8601String();
          batchOps.add({
            'path': '$_decksPath/$remoteId',
            'data': deckData,
            'type': 'set',
          });
        } else if (remoteMod.isAfter(localMod)) {
          // Remote is newer
          final updated = DeckItem.fromMap(remoteMap, remoteId: remoteId);
          updated.id = localDeck.id; // keep local Isar id
          updated.userId = _userId;
          updated.isSynced = true;
          await _local.saveDeck(updated);
        } else if (localMod.isAfter(remoteMod)) {
          // Local is newer → push to remote
          localDeck.remoteId = remoteId;
          localDeck.isSynced = true;
          localDeck.userId = _userId;
          await _local.saveDeck(localDeck);

          batchOps.add({
            'path': '$_decksPath/$remoteId',
            'data': localDeck.toMap(),
            'type': 'set',
          });
        } else {
          // Same timestamp — just ensure remote link
          if (localDeck.remoteId == null) {
            localDeck.remoteId = remoteId;
            localDeck.isSynced = true;
            await _local.saveDeck(localDeck);
          }
        }

        if (!localDeck.isDeleted) {
          cardSyncFutures.add(_syncCardsForDeck(localDeck, remoteId));
        }
      } else if (localDeck != null && remoteMap == null) {
        // LOCAL ONLY
        if (localDeck.isDeleted) continue; // don't push deleted items

        localDeck.userId = _userId;
        localDeck.remoteId = localDeck.remoteId ?? localDeck.syncId;
        localDeck.isSynced = true;
        await _local.saveDeck(localDeck);

        batchOps.add({
          'path': '$_decksPath/${localDeck.remoteId}',
          'data': localDeck.toMap(),
          'type': 'set',
        });

        cardSyncFutures.add(_pushAllCardsForDeck(localDeck, localDeck.remoteId!));
      } else if (localDeck == null && remoteMap != null) {
        // REMOTE ONLY
        if (remoteMap['isDeleted'] == true) continue; // skip deleted

        final remoteId = remoteMap['remoteId'] as String;
        final newDeck = DeckItem.fromMap(remoteMap, remoteId: remoteId);
        newDeck.userId = _userId;
        newDeck.isSynced = true;
        await _local.saveDeck(newDeck);

        cardSyncFutures.add(_pullCardsForDeck(newDeck, remoteId));
      }
    }

    // Execute all card syncs in parallel
    if (cardSyncFutures.isNotEmpty) {
      await Future.wait(cardSyncFutures);
    }

    // Execute all deck-level batch operations
    if (batchOps.isNotEmpty) {
      await _firestore.batchWrite(batchOps);
    }
  }

  Future<void> _syncCardsForDeck(
    DeckItem localDeck,
    String deckRemoteId,
  ) async {
    final cardsPath = _cardsPath(deckRemoteId);

    await localDeck.cards.load();
    final localCards = localDeck.cards.toList();

    List<Map<String, dynamic>> remoteCardsData;
    try {
      remoteCardsData = await _firestore.getCollection(cardsPath);
    } catch (e) {
      if (e is AppException) rethrow;
      throw GeneralException(
        'Failed to fetch cards for deck $deckRemoteId',
        details: e.toString(),
      );
    }

    final localBySyncId = <String, CardItem>{};
    for (final c in localCards) {
      localBySyncId[c.syncId] = c;
    }

    final remoteBySyncId = <String, Map<String, dynamic>>{};
    for (final m in remoteCardsData) {
      final sid = m['syncId'] as String? ?? m['remoteId'] as String? ?? '';
      if (sid.isNotEmpty) remoteBySyncId[sid] = m;
    }

    final allCardSyncIds = <String>{
      ...localBySyncId.keys,
      ...remoteBySyncId.keys,
    };

    final batchOps = <Map<String, dynamic>>[];

    for (final syncId in allCardSyncIds) {
      final localCard = localBySyncId[syncId];
      final remoteMap = remoteBySyncId[syncId];

      if (localCard != null && remoteMap != null) {
        final localMod = localCard.lastModified;
        final remoteMod = remoteMap['lastModified'] != null
            ? DateTime.parse(remoteMap['lastModified'])
            : DateTime.parse(remoteMap['createdAt']);
        final remoteId = remoteMap['remoteId'] as String;

        if (localCard.isDeleted || (remoteMap['isDeleted'] == true)) {
          final now = DateTime.now();
          localCard.isDeleted = true;
          localCard.lastModified = now;
          localCard.remoteId = remoteId;
          localCard.isSynced = true;
          await _local.updateCard(localCard);

          final cardData = localCard.toMap();
          cardData['lastModified'] = now.toIso8601String();

          // Write to both nested and flat paths
          batchOps.add({
            'path': '$cardsPath/$remoteId',
            'data': cardData,
            'type': 'set',
          });
          batchOps.add({
            'path': '$_flashcardsPath/${localCard.syncId}',
            'data': cardData,
            'type': 'set',
          });
        } else if (remoteMod.isAfter(localMod)) {
          // Remote is newer
          final updated = CardItem.fromMap(remoteMap, remoteId: remoteId);
          updated.id = localCard.id;
          updated.userId = _userId;
          updated.isSynced = true;
          updated.deckSyncId = localDeck.syncId;
          await _local.updateCard(updated);
        } else if (localMod.isAfter(remoteMod)) {
          localCard.remoteId = remoteId;
          localCard.isSynced = true;
          await _local.updateCard(localCard);

          final cardData = localCard.toMap();

          // Write to both nested and flat paths
          batchOps.add({
            'path': '$cardsPath/$remoteId',
            'data': cardData,
            'type': 'set',
          });
          batchOps.add({
            'path': '$_flashcardsPath/${localCard.syncId}',
            'data': cardData,
            'type': 'set',
          });
        } else {
          if (localCard.remoteId == null) {
            localCard.remoteId = remoteId;
            localCard.isSynced = true;
            await _local.updateCard(localCard);
          }
        }
      } else if (localCard != null && remoteMap == null) {
        if (localCard.isDeleted) continue;
        localCard.userId = _userId;
        localCard.deckSyncId = localDeck.syncId;
        localCard.remoteId = localCard.syncId;
        localCard.isSynced = true;
        await _local.updateCard(localCard);

        final cardData = localCard.toMap();

        // Push to both nested cards and flat flashcards paths
        batchOps.add({
          'path': '$cardsPath/${localCard.syncId}',
          'data': cardData,
          'type': 'set',
        });
        batchOps.add({
          'path': '$_flashcardsPath/${localCard.syncId}',
          'data': cardData,
          'type': 'set',
        });
      } else if (localCard == null && remoteMap != null) {
        if (remoteMap['isDeleted'] == true) continue;
        final remoteId = remoteMap['remoteId'] as String;
        final newCard = CardItem.fromMap(remoteMap, remoteId: remoteId);
        newCard.userId = _userId;
        newCard.deckSyncId = localDeck.syncId;
        newCard.isSynced = true;
        await _local.addCardToDeck(localDeck.id, newCard);
      }
    }

    // Execute card-level batch operations
    if (batchOps.isNotEmpty) {
      await _firestore.batchWrite(batchOps);
    }
  }

  // Push all of a deck's cards to Firestore in a single batch.
  Future<void> _pushAllCardsForDeck(DeckItem deck, String deckRemoteId) async {
    await deck.cards.load();
    final cards = deck.cards.toList();
    if (cards.isEmpty) return;

    final cardsPath = _cardsPath(deckRemoteId);
    final batchOps = <Map<String, dynamic>>[];

    for (final card in cards) {
      if (card.isDeleted) continue;
      card.userId = _userId;
      card.deckSyncId = deck.syncId;

      final cardData = card.toMap();

      card.remoteId = card.remoteId ?? card.syncId;
      batchOps.add({
        'path': '$cardsPath/${card.remoteId}',
        'data': cardData,
        'type': 'set',
      });
      batchOps.add({
        'path': '$_flashcardsPath/${card.syncId}',
        'data': cardData,
        'type': 'set',
      });
      card.isSynced = true;
      await _local.updateCard(card);
    }

    // Execute all batch operations
    if (batchOps.isNotEmpty) {
      await _firestore.batchWrite(batchOps);
    }
  }

  Future<void> _pullCardsForDeck(DeckItem deck, String deckRemoteId) async {
    final cardsPath = _cardsPath(deckRemoteId);
    try {
      final remoteCards = await _firestore.getCollection(cardsPath);
      for (final cardMap in remoteCards) {
        if (cardMap['isDeleted'] == true) continue;
        final cardRemoteId = cardMap['remoteId'] as String;
        final newCard = CardItem.fromMap(cardMap, remoteId: cardRemoteId);
        newCard.userId = _userId;
        newCard.deckSyncId = deck.syncId;
        newCard.isSynced = true;
        await _local.addCardToDeck(deck.id, newCard);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw GeneralException(
        'Failed to pull cards for deck $deckRemoteId',
        details: e.toString(),
      );
    }
  }

  // FAVORITES SYNC

  Future<void> _syncFavorites() async {
    final localFavs = await _local.getAllFavorites();
    final userLocalFavs = localFavs
        .where((f) => f.userId == _userId || f.userId == null)
        .toList();
    final remoteFavsData = await _firestore.getCollection(_favoritesPath);

    final localBySyncId = <String, FavoriteWord>{};
    for (final f in userLocalFavs) {
      localBySyncId[f.syncId] = f;
    }

    final remoteBySyncId = <String, Map<String, dynamic>>{};
    for (final m in remoteFavsData) {
      final sid = m['syncId'] as String? ?? m['remoteId'] as String? ?? '';
      if (sid.isNotEmpty) remoteBySyncId[sid] = m;
    }

    final allSyncIds = <String>{...localBySyncId.keys, ...remoteBySyncId.keys};
    final batchOps = <Map<String, dynamic>>[];

    for (final syncId in allSyncIds) {
      final local = localBySyncId[syncId];
      final remoteMap = remoteBySyncId[syncId];

      if (local != null && remoteMap != null) {
        final localMod = local.lastModified;
        final remoteMod = remoteMap['lastModified'] != null
            ? DateTime.parse(remoteMap['lastModified'])
            : DateTime.parse(remoteMap['createdAt']);
        final remoteId = remoteMap['remoteId'] as String;

        if (local.isDeleted || (remoteMap['isDeleted'] == true)) {
          final now = DateTime.now();
          local.isDeleted = true;
          local.lastModified = now;
          local.remoteId = remoteId;
          local.isSynced = true;
          await _local.addFavorite(local);

          final favData = local.toMap();
          favData['lastModified'] = now.toIso8601String();
          batchOps.add({
            'path': '$_favoritesPath/$remoteId',
            'data': favData,
            'type': 'set',
          });
        } else if (remoteMod.isAfter(localMod)) {
          // Remote is newer
          final updated = FavoriteWord.fromMap(remoteMap, remoteId: remoteId);
          updated.id = local.id;
          updated.userId = _userId;
          updated.isSynced = true;
          await _local.addFavorite(updated);
        } else if (localMod.isAfter(remoteMod)) {
          local.remoteId = remoteId;
          local.isSynced = true;
          local.userId = _userId;
          await _local.addFavorite(local);
          batchOps.add({
            'path': '$_favoritesPath/$remoteId',
            'data': local.toMap(),
            'type': 'set',
          });
        } else {
          if (local.remoteId == null) {
            local.remoteId = remoteId;
            local.isSynced = true;
            await _local.addFavorite(local);
          }
        }
      } else if (local != null && remoteMap == null) {
        if (local.isDeleted) continue;
        local.userId = _userId;
        final remoteId =
            local.remoteId ??
            await _firestore.addDocument(_favoritesPath, local.toMap());
        local.remoteId = remoteId;
        local.isSynced = true;
        await _local.addFavorite(local);
      } else if (local == null && remoteMap != null) {
        if (remoteMap['isDeleted'] == true) continue;
        final remoteId = remoteMap['remoteId'] as String;
        final newFav = FavoriteWord.fromMap(remoteMap, remoteId: remoteId);
        newFav.userId = _userId;
        newFav.isSynced = true;
        await _local.addFavorite(newFav);
      }
    }

    if (batchOps.isNotEmpty) {
      await _firestore.batchWrite(batchOps);
    }
  }

  // HISTORY SYNC

  Future<void> _syncHistory() async {
    final localHistory = await _local.getAllHistory();
    final userLocalHistory = localHistory
        .where((h) => h.userId == _userId || h.userId == null)
        .toList();
    final remoteHistoryData = await _firestore.getCollection(_historyPath);

    final localBySyncId = <String, HistoryItem>{};
    for (final h in userLocalHistory) {
      localBySyncId[h.syncId] = h;
    }

    final remoteBySyncId = <String, Map<String, dynamic>>{};
    for (final m in remoteHistoryData) {
      final sid = m['syncId'] as String? ?? m['remoteId'] as String? ?? '';
      if (sid.isNotEmpty) remoteBySyncId[sid] = m;
    }

    final allSyncIds = <String>{...localBySyncId.keys, ...remoteBySyncId.keys};
    final batchOps = <Map<String, dynamic>>[];

    for (final syncId in allSyncIds) {
      final local = localBySyncId[syncId];
      final remoteMap = remoteBySyncId[syncId];

      if (local != null && remoteMap != null) {
        final localMod = local.lastModified;
        final remoteMod = remoteMap['lastModified'] != null
            ? DateTime.parse(remoteMap['lastModified'])
            : DateTime.parse(remoteMap['createdAt']);
        final remoteId = remoteMap['remoteId'] as String;

        if (local.isDeleted || (remoteMap['isDeleted'] == true)) {
          final now = DateTime.now();
          local.isDeleted = true;
          local.lastModified = now;
          local.remoteId = remoteId;
          local.isSynced = true;
          await _local.addHistory(local);

          final historyData = local.toMap();
          historyData['lastModified'] = now.toIso8601String();
          batchOps.add({
            'path': '$_historyPath/$remoteId',
            'data': historyData,
            'type': 'set',
          });
        } else if (remoteMod.isAfter(localMod)) {
          // Remote is newer
          final updated = HistoryItem.fromMap(remoteMap, remoteId: remoteId);
          updated.id = local.id;
          updated.userId = _userId;
          updated.isSynced = true;
          await _local.addHistory(updated);
        } else if (localMod.isAfter(remoteMod)) {
          local.remoteId = remoteId;
          local.isSynced = true;
          local.userId = _userId;
          await _local.addHistory(local);
          batchOps.add({
            'path': '$_historyPath/$remoteId',
            'data': local.toMap(),
            'type': 'set',
          });
        } else {
          if (local.remoteId == null) {
            local.remoteId = remoteId;
            local.isSynced = true;
            await _local.addHistory(local);
          }
        }
      } else if (local != null && remoteMap == null) {
        if (local.isDeleted) continue;
        local.userId = _userId;
        final remoteId =
            local.remoteId ??
            await _firestore.addDocument(_historyPath, local.toMap());
        local.remoteId = remoteId;
        local.isSynced = true;
        await _local.addHistory(local);
      } else if (local == null && remoteMap != null) {
        if (remoteMap['isDeleted'] == true) continue;
        final remoteId = remoteMap['remoteId'] as String;
        final newItem = HistoryItem.fromMap(remoteMap, remoteId: remoteId);
        newItem.userId = _userId;
        newItem.isSynced = true;
        await _local.addHistory(newItem);
      }
    }

    if (batchOps.isNotEmpty) {
      await _firestore.batchWrite(batchOps);
    }
  }


  // UTILITY

  Future<void> clearAllLocalData() async {
    await _local.clearAllData();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
