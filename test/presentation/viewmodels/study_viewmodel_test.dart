import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
  test('an empty deck asks for cards; added ones start the session', () async {
    final vm = StudyViewModel(deckOf(0), DeckUsecase(MockDeckRepository()));
    await Future<void>.delayed(Duration.zero);
    expect(vm.deckIsEmpty, isTrue);
    expect(vm.isFinished, isTrue);

    vm.cardsAdded(deckOf(2));

    expect(vm.deckIsEmpty, isFalse);
    expect(vm.isFinished, isFalse);
    expect(vm.currentCard?.word, 'Word0');
  });
}
