import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/history_item_entity.dart';
import 'package:translate_app/domain/usecases/history_usecase.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryUsecase _usecase;

  HistoryViewModel(this._usecase);

  List<HistoryItemEntity> _historyItems = [];
  bool _isLoading = false;
  String? _error;

  List<HistoryItemEntity> get historyItems => _historyItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<void> loadHistory() async {
    _setLoading(true);
    _clearError();

    try {
      _historyItems = await _usecase.executeGetAllHistory();
    } catch (e) {
      _setError('Failed to load history');
    } finally {
      _setLoading(false);
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

    _clearError();
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

    try {
      await _usecase.executeAddHistory(item);
      await loadHistory();
    } catch (e) {
      _setError('Failed to save history item');
    }
  }

  Future<void> deleteItem(int id) async {
    _clearError();
    try {
      await _usecase.executeDeleteHistoryItem(id);
      await loadHistory();
    } catch (e) {
      _setError('Failed to delete history item');
    }
  }

  Future<void> clearAll() async {
    _clearError();
    try {
      await _usecase.executeClearHistory();
      _historyItems = [];
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear history');
    }
  }
}
