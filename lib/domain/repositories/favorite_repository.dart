import '../entities/favorite_word_entity.dart';

abstract class FavoriteRepository {
  Future<List<FavoriteWordEntity>> getAllFavorites();
  Future<void> addFavorite(FavoriteWordEntity favorite);
  Future<void> deleteFavorite(int id);
}
