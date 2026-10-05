import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/domain/entities/study_session.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/ai_study_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/widgets/study_with_ai_button.dart';

class MockAiStudyViewModel extends ChangeNotifier
    with Mock
    implements AiStudyViewModel {}

class MockDecksViewModel extends ChangeNotifier
    with Mock
    implements DecksViewModel {}

class MockEntitlementsViewModel extends ChangeNotifier
    with Mock
    implements EntitlementsViewModel {}

final now = DateTime(2026, 10, 4);

DeckEntity deckOf(int count) => DeckEntity(
  id: 1,
  syncId: 'deck1',
  name: 'English Words',
  createdAt: now,
  lastModified: now,
  cards: [
    for (var i = 0; i < count; i++)
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

EntitlementsEntity plan({required bool chat}) => EntitlementsEntity(
  tier: chat ? AppTier.premium : AppTier.standard,
  entitlements: TierEntitlements(
    maxDecks: null,
    maxCardsPerDeck: null,
    photo: true,
    live: chat,
    chat: chat,
  ),
  translateQuota: const TranslateQuotaStatus.empty(),
);

void main() {
  late MockAiStudyViewModel study;
  late MockDecksViewModel decks;
  late MockEntitlementsViewModel entitlements;

  setUp(() {
    study = MockAiStudyViewModel();
    decks = MockDecksViewModel();
    entitlements = MockEntitlementsViewModel();
    when(() => study.refresh()).thenAnswer((_) async {});
    when(() => study.session).thenReturn(null);
    when(() => study.hasUnfinishedSession).thenReturn(false);
    when(() => study.cooldownLeft).thenReturn(null);
    when(() => decks.decks).thenReturn([deckOf(12)]);
    when(() => entitlements.entitlements).thenReturn(plan(chat: true));
    when(() => entitlements.load()).thenAnswer((_) async {});
    when(() => entitlements.tier).thenReturn(AppTier.standard);
  });

  Widget subject() => MultiProvider(
    providers: [
      ChangeNotifierProvider<AiStudyViewModel>.value(value: study),
      ChangeNotifierProvider<DecksViewModel>.value(value: decks),
      ChangeNotifierProvider<EntitlementsViewModel>.value(value: entitlements),
    ],
    child: const MaterialApp(
      home: Scaffold(body: Center(child: StudyWithAiButton())),
    ),
  );

  testWidgets('ready to study', (tester) async {
    await tester.pumpWidget(subject());

    expect(find.text('Study with AI'), findsOneWidget);
    verify(() => study.refresh()).called(1);
  });

  testWidgets('mid-session it offers to continue', (tester) async {
    final session = StudySession(
      id: 's1',
      deckId: 'deck1',
      deckName: 'English Words',
      items: [
        for (var i = 0; i < 10; i++)
          StudyItem(id: 'c$i', word: 'w$i', translation: 't$i', done: i < 4),
      ],
      current: 4,
      task: 'Task',
    );
    when(() => study.session).thenReturn(session);
    when(() => study.hasUnfinishedSession).thenReturn(true);

    await tester.pumpWidget(subject());

    expect(find.text('Continue · 4/10'), findsOneWidget);
  });

  testWidgets('after a session the countdown is shown', (tester) async {
    when(
      () => study.cooldownLeft,
    ).thenReturn(const Duration(hours: 2, minutes: 41, seconds: 7));

    await tester.pumpWidget(subject());

    expect(find.text('2:41:07'), findsOneWidget);
    expect(find.text('Study with AI'), findsNothing);
  });

  testWidgets('a deck needs 10 words first', (tester) async {
    when(() => decks.decks).thenReturn([deckOf(7)]);

    await tester.pumpWidget(subject());

    expect(find.text('Add 3 more words'), findsOneWidget);
  });

  testWidgets('without Premium it opens the plans', (tester) async {
    when(() => entitlements.entitlements).thenReturn(plan(chat: false));

    await tester.pumpWidget(subject());
    await tester.tap(find.text('Study with AI'));
    await tester.pumpAndSettle();

    expect(find.byType(UpgradePage), findsOneWidget);
  });
}
