import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/domain/repositories/deck_repository.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/widgets/add_card_dialog.dart';

class MockDeckRepository extends Mock implements DeckRepository {}

class MockEntitlementsViewModel extends ChangeNotifier
    with Mock
    implements EntitlementsViewModel {}

/// What GET /entitlements answers, the plan row as Prisma returns it.
EntitlementsEntity plan(String tier, {int? maxDecks, int? maxCardsPerDeck}) =>
    EntitlementsEntity.fromJson({
      'tier': tier,
      'entitlements': {
        'tier': tier,
        'maxDecks': maxDecks,
        'maxCardsPerDeck': maxCardsPerDeck,
        'photo': tier != 'free',
        'live': false,
        'chat': tier != 'free',
        'chatCooldownSeconds': 10800,
      },
      'translate': {'window': 'day', 'limit': 10, 'used': 0},
    });

final now = DateTime(2026, 10, 26);

CardEntity card(int i, {bool deleted = false}) => CardEntity(
  id: i + 1,
  syncId: 'c$i',
  word: 'word$i',
  translation: 'kelime$i',
  createdAt: now,
  lastModified: now,
  isDeleted: deleted,
);

DeckEntity deck(int id, {int cards = 0, int deletedCards = 0}) => DeckEntity(
  id: id,
  syncId: 'd$id',
  name: 'Deck $id',
  createdAt: now,
  lastModified: now,
  cards: [
    for (var i = 0; i < cards; i++) card(i),
    for (var i = 0; i < deletedCards; i++) card(cards + i, deleted: true),
  ],
);

void main() {
  late MockDeckRepository repository;
  late MockEntitlementsViewModel entitlements;
  var stored = <DeckEntity>[];

  setUpAll(() {
    registerFallbackValue(deck(0));
    registerFallbackValue(card(0));
  });

  setUp(() {
    repository = MockDeckRepository();
    entitlements = MockEntitlementsViewModel();
    when(() => repository.getAllDecks()).thenAnswer((_) async => stored);
    when(() => repository.saveDeck(any())).thenAnswer((_) async {});
    when(() => repository.addCardToDeck(any(), any())).thenAnswer((_) async {});
  });

  Future<DecksViewModel> decksWith(
    List<DeckEntity> decks,
    EntitlementsEntity? limits,
  ) async {
    stored = decks;
    when(() => entitlements.entitlements).thenReturn(limits);
    final vm = DecksViewModel(DeckUsecase(repository), entitlements);
    await untilCalled(() => repository.getAllDecks());
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  group('Free (2 decks, 20 cards per deck)', () {
    final free = plan('free', maxDecks: 2, maxCardsPerDeck: 20);

    test('two decks can be made, a third one cannot', () async {
      final empty = await decksWith([deck(1)], free);
      expect(empty.canAddDeck, isTrue);
      expect(await empty.addDeck('Words'), isTrue);
      verify(() => repository.saveDeck(any())).called(1);

      final full = await decksWith([deck(1), deck(2)], free);
      expect(full.canAddDeck, isFalse);
      expect(await full.addDeck('More'), isFalse);
      verifyNever(() => repository.saveDeck(any()));
    });

    test('the 20th card goes in, the 21st does not', () async {
      final vm = await decksWith([deck(1, cards: 19)], free);
      expect(await vm.addCard(1, 'one', 'bir'), isTrue);
      verify(() => repository.addCardToDeck(1, any())).called(1);

      final full = await decksWith([deck(1, cards: 20)], free);
      expect(full.canAddCard(full.decks.single), isFalse);
      expect(await full.addCard(1, 'one', 'bir'), isFalse);
      verifyNever(() => repository.addCardToDeck(any(), any()));
    });

    test('deleted cards free their place', () async {
      final vm = await decksWith([deck(1, cards: 19, deletedCards: 5)], free);
      expect(vm.canAddCard(vm.decks.single), isTrue);
    });
  });

  test('Standard has no deck or card limit', () async {
    final vm = await decksWith([
      deck(1, cards: 500),
      deck(2),
      deck(3),
    ], plan('standard'));
    expect(vm.canAddDeck, isTrue);
    expect(vm.canAddCard(vm.decks.first), isTrue);
  });

  group('Add card from the study screen or a deck', () {
    Future<void> tapAdd(WidgetTester tester, DecksViewModel vm) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => AddCardDialog.show(context, vm.decks.single),
                child: const Text('add'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('add'));
      await tester.pumpAndSettle();
    }

    final free = plan('free', maxDecks: 2, maxCardsPerDeck: 20);

    testWidgets('a full deck gets the limit message, not the form', (
      tester,
    ) async {
      final vm = await tester.runAsync(
        () => decksWith([deck(1, cards: 20)], free),
      );
      await tapAdd(tester, vm!);
      expect(find.text('Card Limit Reached'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a deck with room opens the form', (tester) async {
      final vm = await tester.runAsync(
        () => decksWith([deck(1, cards: 19)], free),
      );
      await tapAdd(tester, vm!);
      expect(find.text('Card Limit Reached'), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });
}
