import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/history_item_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../models/history_model.dart';
import '../services/local_storage_service.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final LocalStorageService _local;
  // Test-only seam: lets unit tests run without Firebase.
  final String? Function() _currentUserIdProvider;

  HistoryRepositoryImpl(this._local, {String? Function()? currentUserId})
    : _currentUserIdProvider = currentUserId ?? _defaultCurrentUserId;

  static String? _defaultCurrentUserId() =>
      FirebaseAuth.instance.currentUser?.uid;

  String? get currentUserId => _currentUserIdProvider();

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
                (i.userId == currentUserId || i.userId == null) && !i.isDeleted,
          )
          .toList();
    }
    return filtered.map(_toEntity).toList();
  }

  @override
  Future<void> addHistory(HistoryItemEntity item) async {
    final historyItem = _toModel(item);
    historyItem.userId = currentUserId;
    historyItem.isSynced = false;
    historyItem.lastModified = DateTime.now();

    if (historyItem.syncId.isEmpty) {
      historyItem.syncId = _generateSyncId();
    }

    // Local write only; the profile "Sync Now" button pushes to the cloud.
    await _local.addHistory(historyItem);
  }

  @override
  Future<void> deleteHistoryItem(int id) async {
    final historyList = await _local.getAllHistory();
    final item = historyList.where((element) => element.id == id).firstOrNull;

    if (item != null) {
      item.isDeleted = true;
      // Keep it flagged so the pending delete survives an app restart.
      item.isSynced = false;
      item.lastModified = DateTime.now();
      await _local.addHistory(item);
    }
  }

  @override
  Future<void> clearHistory() async {
    final historyList = await _local.getAllHistory();

    for (final item in historyList) {
      item.isDeleted = true;
      item.isSynced = false;
      item.lastModified = DateTime.now();
      await _local.addHistory(item);
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
    final item = HistoryItem();
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
