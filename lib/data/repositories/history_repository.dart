import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/history_model.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class HistoryRepository {
  final LocalStorageService _local;
  final FirestoreService _firestore;

  HistoryRepository(this._local, this._firestore);

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String get _collection =>
      currentUserId != null ? 'users/$currentUserId/history' : '';

  Future<List<HistoryItem>> getAllHistory() async {
    final allItems = await _local.getAllHistory();
    if (currentUserId == null) {
      // Logged out: show all non-deleted history so data persists visually
      return allItems.where((i) => !i.isDeleted).toList();
    }
    return allItems
        .where(
          (i) =>
              (i.userId == currentUserId || i.userId == null) && !i.isDeleted,
        )
        .toList();
  }

  Future<void> addHistory(HistoryItem item) async {
    item.userId = currentUserId;
    item.lastModified = DateTime.now();

    if (item.syncId.isEmpty) {
      item.syncId = _generateSyncId();
    }

    // Save locally
    await _local.addHistory(item);

    // Push to firebase if logged in
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
        await _local.addHistory(item);
      } catch (e) {
        debugPrint('History add sync failed: $e');
      }
    }
  }

  Future<void> deleteHistoryItem(int id) async {
    final historyList = await _local.getAllHistory();
    final item = historyList.where((element) => element.id == id).firstOrNull;

    if (item != null) {
      // Soft delete
      item.isDeleted = true;
      item.lastModified = DateTime.now();
      await _local.addHistory(item);

      if (item.remoteId != null && currentUserId != null) {
        try {
          final collectionDir = _collection;
          if (collectionDir.isEmpty) return;
          await _firestore.setDocument(
            '$collectionDir/${item.remoteId}',
            item.toMap(),
          );
        } catch (e) {
          debugPrint('History soft-delete sync failed: $e');
        }
      }
    }
  }

  Future<void> clearHistory() async {
    final historyList = await _local.getAllHistory();

    // Soft delete all
    for (final item in historyList) {
      item.isDeleted = true;
      item.lastModified = DateTime.now();
      await _local.addHistory(item);
    }

    if (currentUserId != null) {
      try {
        final collectionDir = _collection;
        if (collectionDir.isEmpty) return;

        for (var item in historyList) {
          if (item.remoteId != null) {
            await _firestore.setDocument(
              '$collectionDir/${item.remoteId}',
              item.toMap(),
            );
          }
        }
      } catch (e) {
        debugPrint('History clear sync failed: $e');
      }
    }
  }

  String _generateSyncId() {
    final now = DateTime.now();
    final random = now.microsecondsSinceEpoch.toRadixString(36);
    return '${now.millisecondsSinceEpoch.toRadixString(36)}_$random';
  }
}
