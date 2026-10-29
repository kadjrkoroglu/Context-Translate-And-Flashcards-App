import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/data/services/srs_service.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/repositories/deck_repository.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import 'package:translate_app/presentation/viewmodels/study_viewmodel.dart';

class MockDeckRepository extends Mock implements DeckRepository {}

final now = DateTime.now();

DeckEntity deckOf(int count) => DeckEntity(
  id: 1,
  syncId: 'deck1',
  name: 'Deck',
  createdAt: now,
  lastModified: now,
  cards: [
    for (var i = 0; i < count; i++)
      CardEntity(
        id: i + 1,
        syncId: 'c$i',
        word: 'Word$i',
        translation: 'Kelime$i',
        createdAt: now,
        lastModified: now,
      ),
  ],
);

void main() {
  late MockDeckRepository repository;

  setUpAll(() => registerFallbackValue(deckOf(1).cards.single));

  setUp(() {
    repository = MockDeckRepository();
    when(() => repository.updateCard(any())).thenAnswer((_) async {});
  });

  Future<StudyViewModel> start(DeckEntity deck) async {
    final vm = StudyViewModel(deck, DeckUsecase(repository));
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  test('an empty deck asks for cards; added ones start the session', () async {
    final vm = await start(deckOf(0));
    expect(vm.deckIsEmpty, isTrue);
    expect(vm.isFinished, isTrue);

    vm.cardsAdded(deckOf(2));

    expect(vm.deckIsEmpty, isFalse);
    expect(vm.isFinished, isFalse);
    expect(vm.currentCard?.word, 'Word0');
  });

  test('a card rated Again comes back before the session ends', () async {
    final vm = await start(deckOf(2));

    await vm.rateCard(StudyRating.again);
    expect(vm.currentCard?.word, 'Word1');

    await vm.rateCard(StudyRating.good);
    expect(vm.isFinished, isFalse);
    expect(vm.currentCard?.word, 'Word0');

    await vm.rateCard(StudyRating.good);
    expect(vm.isFinished, isTrue);
  });

  test('the last card rated Again or Hard comes straight back', () async {
    final vm = await start(deckOf(1));

    await vm.rateCard(StudyRating.again);
    expect(vm.isFinished, isFalse);
    expect(vm.currentCard?.word, 'Word0');

    await vm.rateCard(StudyRating.hard);
    expect(vm.isFinished, isFalse);

    await vm.rateCard(StudyRating.easy);
    expect(vm.isFinished, isTrue);
  });

  test('a session holds only the new cards left for today', () async {
    final vm = await start(deckOf(30));
    expect(vm.totalCards, 20);

    for (var i = 0; i < 20; i++) {
      await vm.rateCard(StudyRating.good);
    }
    expect(vm.isFinished, isTrue);
    expect(vm.progress, 1.0);
  });

  test('new cards are spread among the reviews', () async {
    final deck = deckOf(6);
    for (final card in deck.cards.take(4)) {
      card
        ..isNewCard = false
        ..interval = 3
        ..nextReviewDate = now.subtract(const Duration(hours: 1));
    }

    final vm = await start(deck);

    expect(vm.dueCards.map((c) => c.isNewCard ? 'new' : 'review'), [
      'review',
      'new',
      'review',
      'new',
      'review',
      'review',
    ]);
  });
}
