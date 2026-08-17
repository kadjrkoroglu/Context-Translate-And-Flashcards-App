import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/history_item_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/history_model.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final LocalStorageService _local;
  final FirestoreService _firestore;

  HistoryRepositoryImpl(this._local, this._firestore);

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String get _collection =>
      currentUserId != null ? 'users/$currentUserId/history' : '';

  @override
  Future<List<HistoryItemEntity>> getAllHistory() async {
    final allItems = await _local.getAllHistory();
    final List<HistoryItem> filtered;
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
  Future<void> addHistory(HistoryItemEntity item) async {
    final historyItem = _toModel(item);
    historyItem.userId = currentUserId;
    historyItem.lastModified = DateTime.now();

    if (historyItem.syncId.isEmpty) {
      historyItem.syncId = _generateSyncId();
    }

    await _local.addHistory(historyItem);

    if (currentUserId != null) {
      try {
        final collectionDir = _collection;
        if (collectionDir.isEmpty) return;

        if (historyItem.remoteId != null) {
          await _firestore.setDocument(
            '$collectionDir/${historyItem.remoteId}',
            historyItem.toMap(),
          );
        } else {
          final remoteId = await _firestore.addDocument(
            collectionDir,
            historyItem.toMap(),
          );
          historyItem.remoteId = remoteId;
        }
        historyItem.isSynced = true;
        await _local.addHistory(historyItem);
      } catch (e) {
        debugPrint('History add sync failed: $e');
      }
    }
  }

  @override
  Future<void> deleteHistoryItem(int id) async {
    final historyList = await _local.getAllHistory();
    final item = historyList.where((element) => element.id == id).firstOrNull;

    if (item != null) {
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

  @override
  Future<void> clearHistory() async {
    final historyList = await _local.getAllHistory();

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

  HistoryItemEntity _toEntity(HistoryItem m) {
    return HistoryItemEntity(
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

  HistoryItem _toModel(HistoryItemEntity e) {
    return HistoryItem()
      ..id = e.id
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
