import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/data/services/tts_service.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/repositories/deck_repository.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import 'package:translate_app/presentation/pages/study_page.dart';
import 'package:translate_app/presentation/viewmodels/study_viewmodel.dart';

class MockDeckRepository extends Mock implements DeckRepository {}

void main() {
  final now = DateTime(2026, 10, 16);
  final deck = DeckEntity(
    id: 1,
    syncId: 'deck1',
    name: 'Words',
    createdAt: now,
    lastModified: now,
    cards: [
      for (var i = 0; i < 2; i++)
        CardEntity(
          id: i + 1,
          syncId: 'c$i',
          word: 'word$i',
          translation: 'kelime$i',
          createdAt: now,
          lastModified: now,
        ),
    ],
  );

  setUpAll(() => registerFallbackValue(deck.cards.first));

  testWidgets('a rated card flies off and the next one comes in', (
    tester,
  ) async {
    final repository = MockDeckRepository();
    when(() => repository.updateCard(any())).thenAnswer((_) async {});
    final vm = StudyViewModel(deck, DeckUsecase(repository));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: vm),
          // The cards' speaker buttons.
          Provider(create: (_) => TtsService()),
        ],
        child: const MaterialApp(home: StudyPage()),
      ),
    );
    await tester.pumpAndSettle();
    final first = vm.currentCard!;

    await tester.tap(find.text('SHOW ANSWER'));
    await tester.pumpAndSettle();
    // Frames between moves, as on a phone, so the card sees the rating zone.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text(first.translation)),
    );
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Mid-flight: the old card is still leaving while the next one appears.
    expect(find.text(first.translation), findsOneWidget);
    expect(vm.currentCard!.id, isNot(first.id));

    await tester.pumpAndSettle();
    expect(find.text(first.translation), findsNothing);
    expect(find.text(vm.currentCard!.word), findsOneWidget);
  });

  testWidgets('a card let go too early slides back', (tester) async {
    final vm = StudyViewModel(deck, DeckUsecase(MockDeckRepository()));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: vm),
          // The cards' speaker buttons.
          Provider(create: (_) => TtsService()),
        ],
        child: const MaterialApp(home: StudyPage()),
      ),
    );
    await tester.pumpAndSettle();
    final first = vm.currentCard!;

    await tester.tap(find.text('SHOW ANSWER'));
    await tester.pumpAndSettle();
    final home = tester.getCenter(find.text(first.translation));
    await tester.drag(find.text(first.translation), const Offset(20, 0));
    await tester.pumpAndSettle();

    expect(vm.currentCard!.id, first.id);
    expect(tester.getCenter(find.text(first.translation)), home);
  });
}
