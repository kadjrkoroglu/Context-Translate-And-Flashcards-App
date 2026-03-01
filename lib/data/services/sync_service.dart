import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:translate_app/data/models/card_model.dart';
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

  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;

  SyncService(this._local, this._firestore);

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // ── Firestore paths ──
  // Decks: users/{uid}/decks/{deckId}
  // Cards: users/{uid}/decks/{deckRemoteId}/cards/{cardId}
  //        (also accessible as users/{uid}/flashcards/{cardSyncId} for flat access)
  // Favorites: users/{uid}/favorites/{favId}
  // History: users/{uid}/history/{historyId}
  String get _decksPath => 'users/$_userId/decks';
  String get _favoritesPath => 'users/$_userId/favorites';
  String get _historyPath => 'users/$_userId/history';
  String _cardsPath(String deckRemoteId) =>
      'users/$_userId/decks/$deckRemoteId/cards';

  /// Flat flashcards path: users/{uid}/flashcards/{cardSyncId}
  String get _flashcardsPath => 'users/$_userId/flashcards';

  /// Main sync entry point — call this from the "Senkronize Et" button.
  ///
  /// Returns an error message string if the user is not logged in,
  /// otherwise returns null on success (check [syncError] for failures).
  Future<String?> syncAll() async {
    // ── Auth guard ──
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
      await _syncDecksAndCards();
      await _syncFavorites();
      await _syncHistory();

      // ── Confirmation: verify lastModified dates are in sync ──
      await _verifyTimestampSync();
    } catch (e) {
      _syncError = e.toString();
      debugPrint('SyncService.syncAll failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return _syncError;
  }

  // ────────────────────────────────────────────
  //  DECKS + CARDS SYNC
  // ────────────────────────────────────────────

  Future<void> _syncDecksAndCards() async {
    final localDecks = await _local.getAllDecks();
    final userLocalDecks = localDecks
        .where((d) => d.userId == _userId || d.userId == null)
        .toList();

    final remoteDecksData = await _firestore.getCollection(_decksPath);

    // Build lookup maps by syncId
    final localBySyncId = <String, DeckItem>{};
    for (final d in userLocalDecks) {
      localBySyncId[d.syncId] = d;
    }

    final remoteBySyncId = <String, Map<String, dynamic>>{};
    for (final m in remoteDecksData) {
      final sid = m['syncId'] as String? ?? m['remoteId'] as String? ?? '';
      if (sid.isNotEmpty) remoteBySyncId[sid] = m;
    }

    // Collect all unique syncIds
    final allSyncIds = <String>{...localBySyncId.keys, ...remoteBySyncId.keys};

    final batchOps = <Map<String, dynamic>>[];

    for (final syncId in allSyncIds) {
      final localDeck = localBySyncId[syncId];
      final remoteMap = remoteBySyncId[syncId];

      if (localDeck != null && remoteMap != null) {
        // ── CONFLICT RESOLUTION ──
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
          // Remote is newer → update local via isar.writeTxn
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

        // Sync cards for this deck
        await _syncCardsForDeck(localDeck, remoteId);
      } else if (localDeck != null && remoteMap == null) {
        // ── LOCAL ONLY → push to remote ──
        if (localDeck.isDeleted) continue; // don't push deleted items

        localDeck.userId = _userId;
        final remoteId =
            localDeck.remoteId ??
            await _firestore.addDocument(_decksPath, localDeck.toMap());
        localDeck.remoteId = remoteId;
        localDeck.isSynced = true;
        await _local.saveDeck(localDeck);

        // Also push cards using batch write
        await _pushAllCardsForDeck(localDeck, remoteId);
      } else if (localDeck == null && remoteMap != null) {
        // ── REMOTE ONLY → pull to local ──
        if (remoteMap['isDeleted'] == true) continue; // skip deleted

        final remoteId = remoteMap['remoteId'] as String;
        final newDeck = DeckItem.fromMap(remoteMap, remoteId: remoteId);
        newDeck.userId = _userId;
        newDeck.isSynced = true;
        await _local.saveDeck(newDeck);

        // Pull cards for this deck
        await _pullCardsForDeck(newDeck, remoteId);
      }
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

    // Load local cards
    await localDeck.cards.load();
    final localCards = localDeck.cards.toList();

    // Fetch remote cards
    List<Map<String, dynamic>> remoteCardsData;
    try {
      remoteCardsData = await _firestore.getCollection(cardsPath);
    } catch (e) {
      debugPrint('Failed to fetch cards for deck $deckRemoteId: $e');
      return;
    }

    // Build lookup maps
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

          // Write to both nested path and flat flashcards path
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
          // Remote is newer → update local via isar.writeTxn
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

          // Write to both nested path and flat flashcards path
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

        final cardData = localCard.toMap();

        // Push to nested cards subcollection
        final remoteId =
            localCard.remoteId ??
            await _firestore.addDocument(cardsPath, cardData);
        localCard.remoteId = remoteId;
        localCard.isSynced = true;
        await _local.updateCard(localCard);

        // Also mirror to flat flashcards path via batch
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

  /// Push all cards for a deck to Firestore using WriteBatch for performance.
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

      // If card already has a remoteId, use it; otherwise generate one
      if (card.remoteId != null) {
        // Add to both nested and flat paths via batch
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
      } else {
        // Need to create document first to get remoteId
        final remoteId = await _firestore.addDocument(cardsPath, cardData);
        card.remoteId = remoteId;
        card.isSynced = true;
        await _local.updateCard(card);

        // Mirror to flat flashcards path via batch
        batchOps.add({
          'path': '$_flashcardsPath/${card.syncId}',
          'data': cardData,
          'type': 'set',
        });
      }
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
        // addCardToDeck already uses isar.writeTxn internally
        await _local.addCardToDeck(deck.id, newCard);
      }
    } catch (e) {
      debugPrint('Pull cards for deck $deckRemoteId failed: $e');
    }
  }

  // ────────────────────────────────────────────
  //  FAVORITES SYNC
  // ────────────────────────────────────────────

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
          // Remote is newer → update local via isar.writeTxn
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

  // ────────────────────────────────────────────
  //  HISTORY SYNC
  // ────────────────────────────────────────────

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
          // Remote is newer → update local via isar.writeTxn
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

  // ────────────────────────────────────────────
  //  TIMESTAMP VERIFICATION
  // ────────────────────────────────────────────

  /// After sync completes, verify that lastModified timestamps are consistent
  /// between Firestore and Isar for all synced items.
  Future<void> _verifyTimestampSync() async {
    final localDecks = await _local.getAllDecks();
    final userDecks = localDecks
        .where((d) => d.userId == _userId && d.isSynced && d.remoteId != null)
        .toList();

    final batchOps = <Map<String, dynamic>>[];

    for (final deck in userDecks) {
      // Verify deck timestamp
      final remoteDeck = await _firestore.getDocument(
        '$_decksPath/${deck.remoteId}',
      );
      if (remoteDeck != null) {
        final remoteLastMod = remoteDeck['lastModified'] != null
            ? DateTime.parse(remoteDeck['lastModified'])
            : null;
        final localLastMod = deck.lastModified;

        // If timestamps diverge, reconcile to the latest and update both sides
        if (remoteLastMod != null && remoteLastMod != localLastMod) {
          final latestMod = remoteLastMod.isAfter(localLastMod)
              ? remoteLastMod
              : localLastMod;

          if (latestMod != localLastMod) {
            deck.lastModified = latestMod;
            await _local.saveDeck(deck);
          }
          if (latestMod != remoteLastMod) {
            final deckData = deck.toMap();
            deckData['lastModified'] = latestMod.toIso8601String();
            batchOps.add({
              'path': '$_decksPath/${deck.remoteId}',
              'data': {'lastModified': latestMod.toIso8601String()},
              'type': 'set',
            });
          }
        }
      }

      // Verify card timestamps
      await deck.cards.load();
      for (final card in deck.cards) {
        if (card.remoteId == null || !card.isSynced) continue;

        final remoteCard = await _firestore.getDocument(
          '$_decksPath/${deck.remoteId}/cards/${card.remoteId}',
        );
        if (remoteCard != null) {
          final remoteCardMod = remoteCard['lastModified'] != null
              ? DateTime.parse(remoteCard['lastModified'])
              : null;
          final localCardMod = card.lastModified;

          if (remoteCardMod != null && remoteCardMod != localCardMod) {
            final latestMod = remoteCardMod.isAfter(localCardMod)
                ? remoteCardMod
                : localCardMod;

            if (latestMod != localCardMod) {
              card.lastModified = latestMod;
              await _local.updateCard(card);
            }
            if (latestMod != remoteCardMod) {
              batchOps.add({
                'path': '$_decksPath/${deck.remoteId}/cards/${card.remoteId}',
                'data': {'lastModified': latestMod.toIso8601String()},
                'type': 'set',
              });
              batchOps.add({
                'path': '$_flashcardsPath/${card.syncId}',
                'data': {'lastModified': latestMod.toIso8601String()},
                'type': 'set',
              });
            }
          }
        }
      }
    }

    if (batchOps.isNotEmpty) {
      await _firestore.batchWrite(batchOps);
    }

    debugPrint('SyncService: Timestamp verification completed.');
  }

  // ────────────────────────────────────────────
  //  UTILITY
  // ────────────────────────────────────────────

  Future<void> clearAllLocalData() async {
    await _local.clearAllData();
  }
}
