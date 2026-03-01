import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/favorite_word_model.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class FavoriteRepository {
  final LocalStorageService _local;
  final FirestoreService _firestore;

  FavoriteRepository(this._local, this._firestore);

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String get _collection =>
      currentUserId != null ? 'users/$currentUserId/favorites' : '';

  Future<List<FavoriteWord>> getAllFavorites() async {
    final allItems = await _local.getAllFavorites();
    if (currentUserId == null) {
      // Logged out: show all non-deleted favorites so data persists visually
      return allItems.where((i) => !i.isDeleted).toList();
    }
    return allItems
        .where(
          (i) =>
              (i.userId == currentUserId || i.userId == null) && !i.isDeleted,
        )
        .toList();
  }

  Future<void> addFavorite(FavoriteWord favorite) async {
    favorite.userId = currentUserId;
    favorite.lastModified = DateTime.now();

    if (favorite.syncId.isEmpty) {
      favorite.syncId = _generateSyncId();
    }

    // Save to local storage first (Offline first)
    await _local.addFavorite(favorite);

    // Try syncing to Firebase
    if (currentUserId != null) {
      try {
        final collectionDir = _collection;
        if (collectionDir.isEmpty) return;

        if (favorite.remoteId != null) {
          await _firestore.setDocument(
            '$collectionDir/${favorite.remoteId}',
            favorite.toMap(),
          );
        } else {
          final remoteId = await _firestore.addDocument(
            collectionDir,
            favorite.toMap(),
          );
          favorite.remoteId = remoteId;
        }
        favorite.isSynced = true;
        await _local.addFavorite(favorite);
      } catch (e) {
        debugPrint('Favorite add sync failed: $e');
      }
    }
  }

  Future<void> deleteFavorite(int id) async {
    final favorites = await _local.getAllFavorites();
    final favorite = favorites.where((element) => element.id == id).firstOrNull;

    if (favorite != null) {
      // Soft delete
      favorite.isDeleted = true;
      favorite.lastModified = DateTime.now();
      await _local.addFavorite(favorite);

      if (favorite.remoteId != null && currentUserId != null) {
        try {
          final collectionDir = _collection;
          if (collectionDir.isEmpty) return;
          await _firestore.setDocument(
            '$collectionDir/${favorite.remoteId}',
            favorite.toMap(),
          );
        } catch (e) {
          debugPrint('Favorite soft-delete sync failed: $e');
        }
      }
    }
  }

  String _generateSyncId() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch.toRadixString(36);
    return '${now.millisecondsSinceEpoch.toRadixString(36)}_$random';
  }
}
