import '../entities/card_entity.dart';
import '../entities/deck_entity.dart';
import '../repositories/deck_repository.dart';

class DeckUsecase {
  final DeckRepository _repository;

  DeckUsecase(this._repository);

  Future<List<DeckEntity>> executeGetAllDecks() =>
      _repository.getAllDecks();

  Future<void> executeSaveDeck(DeckEntity deck) => _repository.saveDeck(deck);

  Future<void> executeDeleteDeck(int id) => _repository.deleteDeck(id);

  Future<void> executeAddCardToDeck(int deckId, CardEntity card) =>
      _repository.addCardToDeck(deckId, card);

  Future<void> executeDeleteCards(List<int> cardIds) =>
      _repository.deleteCards(cardIds);

  Future<void> executeUpdateCard(CardEntity card) =>
      _repository.updateCard(card);

  Future<void> executeUpdateDeckLimits(
    int deckId,
    int newCardsLimit,
    int reviewsLimit,
  ) =>
      _repository.updateDeckLimits(deckId, newCardsLimit, reviewsLimit);
}
