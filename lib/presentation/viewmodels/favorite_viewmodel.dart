import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/favorite_word_entity.dart';
import 'package:translate_app/domain/usecases/favorite_usecase.dart';

class FavoriteViewModel extends ChangeNotifier {
  final FavoriteUsecase _usecase;

  FavoriteViewModel(this._usecase);

  // --- STATE ---
  List<FavoriteWordEntity> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FavoriteWordEntity> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- METHODS ---

  /// Fetch all favorites from database
  Future<void> loadFavorites() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _favorites = await _usecase.executeGetAllFavorites();
    } catch (e) {
      _errorMessage = "Failed to load favorites: $e";
    } finally {
      _setLoading(false);
    }
  }

  /// Add word to favorites
  Future<void> addFavorite({
    required String word,
    required String translation,
    bool isGemini = false,
  }) async {
    final trimmedWord = word.trim();
    final trimmedTranslation = translation.trim();

    if (trimmedWord.isEmpty || trimmedTranslation.isEmpty) return;

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
      _errorMessage = "Save failed: $e";
      notifyListeners();
    }
  }

  /// Delete favorite by ID
  Future<void> removeFavorite(int id) async {
    try {
      await _usecase.executeDeleteFavorite(id);
      await loadFavorites();
    } catch (e) {
      _errorMessage = "Delete failed: $e";
      notifyListeners();
    }
  }

  /// Check if word is already favorited
  bool isFavorite(String word) {
    final trimmed = word.trim().toLowerCase();
    return _favorites.any((f) => f.word.toLowerCase() == trimmed);
  }

  /// Toggle favorite status
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
      // Remove all matches to avoid duplicates
      for (var fav in existing) {
        await removeFavorite(fav.id);
      }
    } else {
      // Add if not exists
      await addFavorite(
        word: word.trim(),
        translation: translation.trim(),
        isGemini: isGemini,
      );
    }
  }

  /// Update loading state and notify UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
