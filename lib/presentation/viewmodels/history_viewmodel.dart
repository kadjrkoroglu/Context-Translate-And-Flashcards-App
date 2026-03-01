import 'package:flutter/material.dart';
import '../../data/models/history_model.dart';
import '../../data/repositories/history_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryRepository _repository;

  HistoryViewModel(this._repository);

  List<HistoryItem> _historyItems = [];
  bool _isLoading = false;

  List<HistoryItem> get historyItems => _historyItems;
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _historyItems = await _repository.getAllHistory();
    } catch (e) {
      debugPrint('Load history error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHistoryItem({
    required String word,
    required String translation,
  }) async {
    // If history is empty, ensure it's loaded first to check for duplicates
    if (_historyItems.isEmpty && !_isLoading) {
      await loadHistory();
    }

    // Don't save if it's the same as the last entry
    if (_historyItems.isNotEmpty) {
      final lastItem = _historyItems.first;
      if (lastItem.word.trim() == word.trim() &&
          lastItem.translation.trim() == translation.trim()) {
        return;
      }
    }

    final now = DateTime.now();
    final item = HistoryItem()
      ..syncId =
          '${now.millisecondsSinceEpoch.toRadixString(36)}_${now.microsecondsSinceEpoch.toRadixString(36)}'
      ..word = word
      ..translation = translation
      ..createdAt = now
      ..lastModified = now;

    await _repository.addHistory(item);
    await loadHistory();
  }

  Future<void> deleteItem(int id) async {
    await _repository.deleteHistoryItem(id);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await _repository.clearHistory();
    _historyItems = [];
    notifyListeners();
  }
}
