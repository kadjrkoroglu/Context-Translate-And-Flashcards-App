import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/domain/entities/card_entity.dart';
import 'package:translate_app/domain/entities/deck_entity.dart';
import 'package:translate_app/domain/repositories/deck_repository.dart';
import 'package:translate_app/domain/usecases/deck_usecase.dart';

class MockDeckRepository extends Mock implements DeckRepository {}

void main() {
  late MockDeckRepository mockRepository;
  late DeckUsecase usecase;

  setUp(() {
    mockRepository = MockDeckRepository();
    usecase = DeckUsecase(mockRepository);
  });

  final testDeck = DeckEntity(
    id: 1,
    syncId: 'sync-1',
    name: 'Test Deck',
    createdAt: DateTime(2025),
    lastModified: DateTime(2025),
    cards: [
      CardEntity(
        id: 1,
        syncId: 'card-sync-1',
        word: 'hello',
        translation: 'merhaba',
        createdAt: DateTime(2025),
        lastModified: DateTime(2025),
      ),
    ],
  );

  final testCard = CardEntity(
    id: 2,
    syncId: 'card-sync-2',
    word: 'world',
    translation: 'dünya',
    createdAt: DateTime(2025),
    lastModified: DateTime(2025),
  );

  group('executeGetAllDecks', () {
    test('returns list of decks from repository', () async {
      when(() => mockRepository.getAllDecks()).thenAnswer(
        (_) async => [testDeck],
      );

      final result = await usecase.executeGetAllDecks();

      expect(result, hasLength(1));
      expect(result.first.name, 'Test Deck');
      expect(result.first.cards, hasLength(1));
    });

    test('calls repository getAllDecks exactly once', () async {
      when(() => mockRepository.getAllDecks()).thenAnswer(
        (_) async => [testDeck],
      );

      await usecase.executeGetAllDecks();

      verify(() => mockRepository.getAllDecks()).called(1);
    });
  });

  group('executeSaveDeck', () {
    test('calls repository saveDeck with correct deck', () async {
      when(() => mockRepository.saveDeck(testDeck)).thenAnswer((_) async {});

      await usecase.executeSaveDeck(testDeck);

      verify(() => mockRepository.saveDeck(testDeck)).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.saveDeck(testDeck),
      ).thenThrow(Exception('save failed'));

      expect(() => usecase.executeSaveDeck(testDeck), throwsException);
    });
  });

  group('executeDeleteDeck', () {
    test('calls repository deleteDeck with correct id', () async {
      when(() => mockRepository.deleteDeck(1)).thenAnswer((_) async {});

      await usecase.executeDeleteDeck(1);

      verify(() => mockRepository.deleteDeck(1)).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.deleteDeck(99),
      ).thenThrow(Exception('not found'));

      expect(() => usecase.executeDeleteDeck(99), throwsException);
    });
  });

  group('executeAddCardToDeck', () {
    test('calls repository addCardToDeck with correct parameters', () async {
      when(
        () => mockRepository.addCardToDeck(1, testCard),
      ).thenAnswer((_) async {});

      await usecase.executeAddCardToDeck(1, testCard);

      verify(() => mockRepository.addCardToDeck(1, testCard)).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.addCardToDeck(1, testCard),
      ).thenThrow(Exception('deck not found'));

      expect(
        () => usecase.executeAddCardToDeck(1, testCard),
        throwsException,
      );
    });
  });

  group('executeDeleteCards', () {
    test('calls repository deleteCards with correct ids', () async {
      when(() => mockRepository.deleteCards([1, 2])).thenAnswer((_) async {});

      await usecase.executeDeleteCards([1, 2]);

      verify(() => mockRepository.deleteCards([1, 2])).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.deleteCards([1, 2]),
      ).thenThrow(Exception('delete failed'));

      expect(() => usecase.executeDeleteCards([1, 2]), throwsException);
    });
  });

  group('executeUpdateDeckLimits', () {
    test('calls repository with correct limits', () async {
      when(
        () => mockRepository.updateDeckLimits(1, 30, 200),
      ).thenAnswer((_) async {});

      await usecase.executeUpdateDeckLimits(1, 30, 200);

      verify(() => mockRepository.updateDeckLimits(1, 30, 200)).called(1);
    });
  });
}
