import 'package:flutter/material.dart';
import '../../data/models/favorite_word_model.dart';
import '../../data/repositories/favorite_repository.dart';

class FavoriteViewModel extends ChangeNotifier {
  final FavoriteRepository _repository;

  FavoriteViewModel(this._repository);

  // --- STATE ---
  List<FavoriteWord> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FavoriteWord> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- METHODS ---

  /// Fetch all favorites from database
  Future<void> loadFavorites() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _favorites = await _repository.getAllFavorites();
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
  }) async {
    final trimmedWord = word.trim();
    final trimmedTranslation = translation.trim();

    if (trimmedWord.isEmpty || trimmedTranslation.isEmpty) return;

    try {
      final now = DateTime.now();
      final newFavorite = FavoriteWord()
        ..syncId =
            '${now.millisecondsSinceEpoch.toRadixString(36)}_${now.microsecondsSinceEpoch.toRadixString(36)}'
        ..word = trimmedWord
        ..translation = trimmedTranslation
        ..createdAt = now
        ..lastModified = now;

      await _repository.addFavorite(newFavorite);
      await loadFavorites();
    } catch (e) {
      _errorMessage = "Save failed: $e";
      notifyListeners();
    }
  }

  /// Delete favorite by ID
  Future<void> removeFavorite(int id) async {
    try {
      await _repository.deleteFavorite(id);
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
  }) async {
    final trimmedWord = word.trim().toLowerCase();
    final existing = _favorites.where(
      (f) => f.word.toLowerCase() == trimmedWord,
    );

    if (existing.isNotEmpty) {
      // Remove all matches to avoid duplicates
      for (var fav in existing) {
        await removeFavorite(fav.id);
      }
    } else {
      // Add if not exists
      await addFavorite(word: word.trim(), translation: translation.trim());
    }
  }

  /// Update loading state and notify UI
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
