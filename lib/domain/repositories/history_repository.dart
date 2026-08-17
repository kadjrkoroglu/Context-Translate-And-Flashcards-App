import '../entities/history_item_entity.dart';

abstract class HistoryRepository {
  Future<List<HistoryItemEntity>> getAllHistory();
  Future<void> addHistory(HistoryItemEntity item);
  Future<void> deleteHistoryItem(int id);
  Future<void> clearHistory();
}
