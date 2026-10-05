import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/services/settings_service.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/entities/study_session.dart';
import 'package:translate_app/domain/repositories/deck_repository.dart';
import 'package:translate_app/domain/repositories/translation_repository.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';
import 'package:translate_app/domain/usecases/translate_usecase.dart';
import 'package:translate_app/presentation/viewmodels/ai_study_viewmodel.dart';

class MockTranslationRepository extends Mock implements TranslationRepository {}

class MockDeckRepository extends Mock implements DeckRepository {}

final now = DateTime(2026, 10, 4, 12);

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

/// A session over c0..c9 where [done] cards are finished.
StudySession sessionOf({
  int done = 0,
  String? task = 'Task 1',
  List<int> misses = const [],
  String id = 's1',
}) {
  final completed = done == 10;
  return StudySession(
    id: id,
    deckId: 'deck1',
    deckName: 'English Words',
    items: [
      for (var i = 0; i < 10; i++)
        StudyItem(
          id: 'c$i',
          word: 'word$i',
          translation: 'kelime$i',
          done: i < done,
          misses: misses.contains(i) ? 1 : 0,
        ),
    ],
    current: completed ? null : done,
    task: completed ? null : task,
    completed: completed,
  );
}

void main() {
  late MockTranslationRepository repository;
  late MockDeckRepository decks;
  late SettingsService settings;
  late AiStudyViewModel vm;
  final deck = deckOf(12);

  setUpAll(() => registerFallbackValue(deckOf(1).cards.first));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
    repository = MockTranslationRepository();
    decks = MockDeckRepository();
    when(() => decks.getAllDecks()).thenAnswer((_) async => [deck]);
    when(() => decks.updateCard(any())).thenAnswer((_) async {});
    vm = AiStudyViewModel(
      TranslateUsecase(repository),
      DeckUsecase(decks),
      settings,
      now: () => now,
    );
  });

  tearDown(() => vm.dispose());

  Future<void> startSession() async {
    when(
      () => repository.startStudy(
        deckId: any(named: 'deckId'),
        deckName: any(named: 'deckName'),
        cards: any(named: 'cards'),
      ),
    ).thenAnswer(
      (_) async => StudyStart(
        state: StudyState(session: sessionOf()),
        greeting: 'Hi!',
      ),
    );
    await vm.open(deck);
  }

  void replyWith(StudyReply reply) {
    when(
      () => repository.answerStudy(any(), any()),
    ).thenAnswer((_) async => reply);
  }

  List<String> texts() => [for (final m in vm.messages) m.text];

  test('starting shows the greeting and the first task', () async {
    await startSession();

    expect(texts(), ['Hi!', 'Task 1']);
    expect(vm.messages.last.label, '1/10');
    final sent =
        verify(
              () => repository.startStudy(
                deckId: 'deck1',
                deckName: 'English Words',
                cards: captureAny(named: 'cards'),
              ),
            ).captured.single
            as List<({String id, String word, String translation})>;
    expect(sent, hasLength(10));
  });

  test('the 10 picked cards are marked so they are not picked next', () async {
    await startSession();

    final updated = verify(
      () => decks.updateCard(captureAny()),
    ).captured.cast<CardEntity>();
    expect(updated, hasLength(10));
    expect(updated.every((c) => c.aiStudiedAt == now), isTrue);
  });

  test('a correct answer gets a tick, then the next task', () async {
    await startSession();
    replyWith(
      StudyReply(
        verdict: StudyVerdict.correct,
        feedback: 'Great!',
        state: StudyState(session: sessionOf(done: 1, task: 'Task 2')),
      ),
    );

    await vm.send('word0');

    expect(texts().skip(2), ['word0', 'Great!', 'Task 2']);
    expect(vm.messages[3].correct, isTrue);
    expect(vm.messages.last.label, '2/10');
  });

  test('an off-topic message gets no reply from the tutor', () async {
    await startSession();
    replyWith(
      StudyReply(
        verdict: StudyVerdict.offTopic,
        state: StudyState(session: sessionOf()),
      ),
    );

    await vm.send('Write me a poem');

    expect(vm.messages.last.kind, StudyMessageKind.note);
    expect(vm.messages.last.text, AiStudyViewModel.offTopicNote);
    expect(
      vm.messages.where((m) => m.kind == StudyMessageKind.task),
      hasLength(1),
    );
  });

  test(
    'a hint keeps the same task; a second miss brings the next one',
    () async {
      await startSession();
      replyWith(
        StudyReply(
          verdict: StudyVerdict.wrong,
          feedback: 'It starts with w.',
          state: StudyState(session: sessionOf()),
        ),
      );
      await vm.send('apple');
      expect(texts().last, 'It starts with w.');

      replyWith(
        StudyReply(
          verdict: StudyVerdict.wrong,
          feedback: 'It was word0.',
          revealed: true,
          state: StudyState(session: sessionOf(task: 'Task for word1')),
        ),
      );
      await vm.send('apple');

      expect(texts().skip(texts().length - 2), [
        'It was word0.',
        'Task for word1',
      ]);
    },
  );

  test(
    'finishing starts the countdown and flags the cards that needed help',
    () async {
      await startSession();
      clearInteractions(decks);
      replyWith(
        StudyReply(
          verdict: StudyVerdict.correct,
          feedback: 'Done!',
          state: StudyState(
            session: sessionOf(done: 10, misses: [2, 5]),
            nextAvailableAt: now.add(const Duration(hours: 3)),
          ),
        ),
      );

      await vm.send('word9');

      expect(vm.session!.completed, isTrue);
      expect(vm.cooldownLeft, const Duration(hours: 3));
      expect(settings.aiStudyChat, isNull);
      final updated = verify(
        () => decks.updateCard(captureAny()),
      ).captured.cast<CardEntity>();
      expect(
        {for (final c in updated) c.syncId: c.aiNeedsReview},
        {for (var i = 0; i < 10; i++) 'c$i': i == 2 || i == 5},
      );
    },
  );

  test('coming back resumes the saved chat', () async {
    await startSession();
    final saved = texts();
    final fresh = AiStudyViewModel(
      TranslateUsecase(repository),
      DeckUsecase(decks),
      settings,
      now: () => now,
    );
    when(
      () => repository.fetchStudyState(),
    ).thenAnswer((_) async => StudyState(session: sessionOf()));

    await fresh.refresh();
    await fresh.open(null);

    expect([for (final m in fresh.messages) m.text], saved);
    fresh.dispose();
  });

  test('without a saved chat it says how many words are left', () async {
    await settings.setAiStudyChat(
      jsonEncode({'sessionId': 'other', 'messages': []}),
    );
    when(() => repository.fetchStudyState()).thenAnswer(
      (_) async => StudyState(session: sessionOf(done: 4, task: 'Task 5')),
    );

    await vm.refresh();
    await vm.open(null);

    expect(texts(), ['Welcome back, 6 words to go.', 'Task 5']);
    expect(vm.messages.last.label, '5/10');
  });

  test('a failed answer is retried without a second bubble', () async {
    await startSession();
    when(
      () => repository.answerStudy(any(), any()),
    ).thenThrow(const NetworkException('offline'));

    await vm.send('word0');
    expect(vm.error, isA<NetworkException>());

    replyWith(
      StudyReply(
        verdict: StudyVerdict.correct,
        feedback: 'Great!',
        state: StudyState(session: sessionOf(done: 1, task: 'Task 2')),
      ),
    );
    await vm.retry();

    expect(vm.error, isNull);
    expect(texts().where((t) => t == 'word0'), hasLength(1));
    verify(() => repository.answerStudy('s1', 'word0')).called(2);
  });

  test('starting during the cooldown shows how long is left', () async {
    when(
      () => repository.startStudy(
        deckId: any(named: 'deckId'),
        deckName: any(named: 'deckName'),
        cards: any(named: 'cards'),
      ),
    ).thenThrow(const QuotaExceededException('cooldown'));
    when(() => repository.fetchStudyState()).thenAnswer(
      (_) async => StudyState(
        nextAvailableAt: now.add(const Duration(hours: 2, minutes: 41)),
      ),
    );

    await vm.open(deck);

    expect(vm.error, isA<QuotaExceededException>());
    expect(vm.cooldownLeft, const Duration(hours: 2, minutes: 41));
  });

  test('countdown format', () {
    expect(
      formatCountdown(const Duration(hours: 2, minutes: 41, seconds: 7)),
      '2:41:07',
    );
    expect(formatCountdown(const Duration(minutes: 41, seconds: 7)), '41:07');
  });
}
