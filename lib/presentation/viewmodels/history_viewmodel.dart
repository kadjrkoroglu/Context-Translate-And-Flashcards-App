import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/history_item_entity.dart';
import 'package:translate_app/domain/usecases/history_usecase.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryUsecase _usecase;

  HistoryViewModel(this._usecase);

  List<HistoryItemEntity> _historyItems = [];
  bool _isLoading = false;

  List<HistoryItemEntity> get historyItems => _historyItems;
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _historyItems = await _usecase.executeGetAllHistory();
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
    bool isGemini = false,
  }) async {
    if (_historyItems.isEmpty && !_isLoading) {
      await loadHistory();
    }

    if (_historyItems.isNotEmpty) {
      final lastItem = _historyItems.first;
      if (lastItem.word.trim() == word.trim() &&
          lastItem.translation.trim() == translation.trim() &&
          lastItem.isGemini == isGemini) {
        return;
      }
    }

    final now = DateTime.now();
    final item = HistoryItemEntity(
      id: 0,
      syncId:
          '${now.millisecondsSinceEpoch.toRadixString(36)}_${now.microsecondsSinceEpoch.toRadixString(36)}',
      word: word,
      translation: translation,
      createdAt: now,
      lastModified: now,
      isGemini: isGemini,
    );

    await _usecase.executeAddHistory(item);
    await loadHistory();
  }

  Future<void> deleteItem(int id) async {
    await _usecase.executeDeleteHistoryItem(id);
    await loadHistory();
  }

  Future<void> clearAll() async {
    await _usecase.executeClearHistory();
    _historyItems = [];
    notifyListeners();
  }
}
