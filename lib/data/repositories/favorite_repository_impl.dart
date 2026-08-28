import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/favorite_word_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../models/favorite_word_model.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final LocalStorageService _local;
  final FirestoreService _firestore;
  // Test-only seam: lets unit tests run without Firebase.
  final String? Function() _currentUserIdProvider;

  FavoriteRepositoryImpl(
    this._local,
    this._firestore, {
    String? Function()? currentUserId,
  }) : _currentUserIdProvider = currentUserId ?? _defaultCurrentUserId;

  static String? _defaultCurrentUserId() =>
      FirebaseAuth.instance.currentUser?.uid;

  String? get currentUserId => _currentUserIdProvider();

  String get _collection =>
      currentUserId != null ? 'users/$currentUserId/favorites' : '';

  @override
  Future<List<FavoriteWordEntity>> getAllFavorites() async {
    final allItems = await _local.getAllFavorites();
    final List<FavoriteWord> filtered;
    if (currentUserId == null) {
      filtered = allItems.where((i) => !i.isDeleted).toList();
    } else {
      filtered = allItems
          .where(
            (i) =>
                (i.userId == currentUserId || i.userId == null) &&
                !i.isDeleted,
          )
          .toList();
    }
    return filtered.map(_toEntity).toList();
  }

  @override
  Future<void> addFavorite(FavoriteWordEntity favorite) async {
    final item = _toModel(favorite);
    item.userId = currentUserId;
    item.lastModified = DateTime.now();

    if (item.syncId.isEmpty) {
      item.syncId = _generateSyncId();
    }

    await _local.addFavorite(item);

    if (currentUserId != null) {
      try {
        final collectionDir = _collection;
        if (collectionDir.isEmpty) return;

        if (item.remoteId != null) {
          await _firestore.setDocument(
            '$collectionDir/${item.remoteId}',
            item.toMap(),
          );
        } else {
          final remoteId = await _firestore.addDocument(
            collectionDir,
            item.toMap(),
          );
          item.remoteId = remoteId;
        }
        item.isSynced = true;
        await _local.addFavorite(item);
      } catch (e) {
        if (e is AppException) rethrow;
        debugPrint('Favorite add sync failed: $e');
      }
    }
  }

  @override
  Future<void> deleteFavorite(int id) async {
    final favorites = await _local.getAllFavorites();
    final favorite = favorites.where((element) => element.id == id).firstOrNull;

    if (favorite != null) {
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
        if (e is AppException) rethrow;
        debugPrint('Favorite soft-delete sync failed: $e');
      }
      }
    }
  }

  FavoriteWordEntity _toEntity(FavoriteWord m) {
    return FavoriteWordEntity(
      id: m.id,
      syncId: m.syncId,
      word: m.word,
      translation: m.translation,
      createdAt: m.createdAt,
      lastModified: m.lastModified,
      userId: m.userId,
      remoteId: m.remoteId,
      isSynced: m.isSynced,
      isDeleted: m.isDeleted,
      isGemini: m.isGemini,
    );
  }

  FavoriteWord _toModel(FavoriteWordEntity e) {
    final item = FavoriteWord();
    // id 0 = new item; keep autoIncrement to avoid overwriting row 0.
    if (e.id != 0) {
      item.id = e.id;
    }
    return item
      ..syncId = e.syncId
      ..word = e.word
      ..translation = e.translation
      ..createdAt = e.createdAt
      ..lastModified = e.lastModified
      ..userId = e.userId
      ..remoteId = e.remoteId
      ..isSynced = e.isSynced
      ..isDeleted = e.isDeleted
      ..isGemini = e.isGemini;
  }

  String _generateSyncId() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch.toRadixString(36);
    return '${now.millisecondsSinceEpoch.toRadixString(36)}_$random';
  }
}
