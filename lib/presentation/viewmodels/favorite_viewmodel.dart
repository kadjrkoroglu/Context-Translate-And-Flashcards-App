import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/favorite_word_entity.dart';
import 'package:translate_app/domain/usecases/favorite_usecase.dart';

class FavoriteViewModel extends ChangeNotifier {
  final FavoriteUsecase _usecase;

  FavoriteViewModel(this._usecase);

  List<FavoriteWordEntity> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<FavoriteWordEntity> get favorites => _favorites;
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

  Future<void> loadFavorites() async {
    _setLoading(true);
    _clearError();

    try {
      _favorites = await _usecase.executeGetAllFavorites();
    } catch (e) {
      _setError('Failed to load favorites');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addFavorite({
    required String word,
    required String translation,
    bool isGemini = false,
  }) async {
    final trimmedWord = word.trim();
    final trimmedTranslation = translation.trim();

    if (trimmedWord.isEmpty || trimmedTranslation.isEmpty) return;

    _clearError();
    try {
      final now = DateTime.now();
      final newFavorite = FavoriteWordEntity(
        id: 0,
        syncId:
            '${now.millisecondsSinceEpoch.toRadixString(36)}_${now.microsecondsSinceEpoch.toRadixString(36)}',
        word: trimmedWord,
        translation: trimmedTranslation,
        createdAt: now,
        lastModified: now,
        isGemini: isGemini,
      );

      await _usecase.executeAddFavorite(newFavorite);
      await loadFavorites();
    } catch (e) {
      _setError('Failed to save favorite');
    }
  }

  Future<void> removeFavorite(int id) async {
    _clearError();
    try {
      await _usecase.executeDeleteFavorite(id);
      await loadFavorites();
    } catch (e) {
      _setError('Failed to delete favorite');
    }
  }

  bool isFavorite(String word) {
    final trimmed = word.trim().toLowerCase();
    return _favorites.any((f) => f.word.toLowerCase() == trimmed);
  }

  Future<void> toggleFavorite({
    required String word,
    required String translation,
    bool isGemini = false,
  }) async {
    final trimmedWord = word.trim().toLowerCase();
    final existing = _favorites.where(
      (f) => f.word.toLowerCase() == trimmedWord && f.isGemini == isGemini,
    );

    if (existing.isNotEmpty) {
      for (var fav in existing) {
        await removeFavorite(fav.id);
      }
    } else {
      await addFavorite(
        word: word.trim(),
        translation: translation.trim(),
        isGemini: isGemini,
      );
    }
  }
}
