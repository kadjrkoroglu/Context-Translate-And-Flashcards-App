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
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/decks_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/subscription_viewmodel.dart';
import 'package:translate_app/presentation/widgets/study_with_ai_button.dart';

class MockAiStudyViewModel extends ChangeNotifier
    with Mock
    implements AiStudyViewModel {}

class MockAuthViewModel extends ChangeNotifier
    with Mock
    implements AuthViewModel {}

class MockDecksViewModel extends ChangeNotifier
    with Mock
    implements DecksViewModel {}

class MockEntitlementsViewModel extends ChangeNotifier
    with Mock
    implements EntitlementsViewModel {}

class MockSubscriptionViewModel extends ChangeNotifier
    with Mock
    implements SubscriptionViewModel {}

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
  final auth = MockAuthViewModel();
  when(() => auth.isAuthenticated).thenReturn(false);
  final plans = MockSubscriptionViewModel();
  setUpAll(() => registerFallbackValue(PlanOption.premium));
  when(() => plans.load()).thenAnswer((_) async {});
  when(() => plans.isBusy).thenReturn(false);
  when(() => plans.loadFailed).thenReturn(false);
  setUpAll(() {
    when(() => plans.priceOf(any())).thenReturn(null);
    when(() => plans.trialDaysOf(any())).thenReturn(null);
    when(() => plans.trialAvailable(any())).thenReturn(false);
  });

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
      ChangeNotifierProvider<AuthViewModel>.value(value: auth),
      ChangeNotifierProvider<SubscriptionViewModel>.value(value: plans),
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

  testWidgets('Continue without the deck on the phone offers to end it', (
    tester,
  ) async {
    final session = StudySession(
      id: 's1',
      deckId: 'gone',
      deckName: 'Old Deck',
      items: const [],
    );
    when(() => study.session).thenReturn(session);
    when(() => study.hasUnfinishedSession).thenReturn(true);
    when(() => study.endSession()).thenAnswer((_) async => true);

    await tester.pumpWidget(subject());
    await tester.tap(find.textContaining('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Deck not on this phone'), findsOneWidget);
    expect(find.text('Sync now'), findsNothing);
    await tester.tap(find.text('End session'));
    await tester.pumpAndSettle();
    verify(() => study.endSession()).called(1);
  });
}
