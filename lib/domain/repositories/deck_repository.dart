import '../entities/card_entity.dart';
import '../entities/deck_entity.dart';

abstract class DeckRepository {
  Future<List<DeckEntity>> getAllDecks();
  Future<void> saveDeck(DeckEntity deck);
  Future<void> deleteDeck(int id);
  Future<void> addCardToDeck(int deckId, CardEntity card);
  Future<void> deleteCards(List<int> cardIds);
  Future<void> updateCard(CardEntity card);
  Future<void> updateDeckLimits(
    int deckId,
    int newCardsLimit,
    int reviewsLimit,
  );
}
