import '../entities/history_item_entity.dart';
import '../repositories/history_repository.dart';

class HistoryUsecase {
  final HistoryRepository _repository;

  HistoryUsecase(this._repository);

  Future<List<HistoryItemEntity>> executeGetAllHistory() =>
      _repository.getAllHistory();

  Future<void> executeAddHistory(HistoryItemEntity item) =>
      _repository.addHistory(item);

  Future<void> executeDeleteHistoryItem(int id) =>
      _repository.deleteHistoryItem(id);

  Future<void> executeClearHistory() => _repository.clearHistory();
}
