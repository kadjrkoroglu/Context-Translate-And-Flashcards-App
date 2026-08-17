import '../entities/favorite_word_entity.dart';
import '../repositories/favorite_repository.dart';

class FavoriteUsecase {
  final FavoriteRepository _repository;

  FavoriteUsecase(this._repository);

  Future<List<FavoriteWordEntity>> executeGetAllFavorites() =>
      _repository.getAllFavorites();

  Future<void> executeAddFavorite(FavoriteWordEntity favorite) =>
      _repository.addFavorite(favorite);

  Future<void> executeDeleteFavorite(int id) =>
      _repository.deleteFavorite(id);
}
