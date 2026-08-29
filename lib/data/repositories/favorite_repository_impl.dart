import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/favorite_word_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../models/favorite_word_model.dart';
import '../services/local_storage_service.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final LocalStorageService _local;
  // Test-only seam: lets unit tests run without Firebase.
  final String? Function() _currentUserIdProvider;

  FavoriteRepositoryImpl(this._local, {String? Function()? currentUserId})
    : _currentUserIdProvider = currentUserId ?? _defaultCurrentUserId;

  static String? _defaultCurrentUserId() =>
      FirebaseAuth.instance.currentUser?.uid;

  String? get currentUserId => _currentUserIdProvider();

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
                (i.userId == currentUserId || i.userId == null) && !i.isDeleted,
          )
          .toList();
    }
    return filtered.map(_toEntity).toList();
  }

  @override
  Future<void> addFavorite(FavoriteWordEntity favorite) async {
    final item = _toModel(favorite);
    item.userId = currentUserId;
    item.isSynced = false;
    item.lastModified = DateTime.now();

    if (item.syncId.isEmpty) {
      item.syncId = _generateSyncId();
    }

    // Local write only; the profile "Sync Now" button pushes to the cloud.
    await _local.addFavorite(item);
  }

  @override
  Future<void> deleteFavorite(int id) async {
    final favorites = await _local.getAllFavorites();
    final favorite = favorites.where((element) => element.id == id).firstOrNull;

    if (favorite != null) {
      favorite.isDeleted = true;
      // Keep it flagged so the pending delete survives an app restart.
      favorite.isSynced = false;
      favorite.lastModified = DateTime.now();
      await _local.addFavorite(favorite);
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
