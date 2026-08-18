import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/domain/entities/history_item_entity.dart';
import 'package:translate_app/domain/repositories/history_repository.dart';
import 'package:translate_app/domain/usecases/history_usecase.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockHistoryRepository mockRepository;
  late HistoryUsecase usecase;

  setUp(() {
    mockRepository = MockHistoryRepository();
    usecase = HistoryUsecase(mockRepository);
  });

  final testItem = HistoryItemEntity(
    id: 1,
    syncId: 'hist-sync-1',
    word: 'hello',
    translation: 'merhaba',
    createdAt: DateTime(2025),
    lastModified: DateTime(2025),
    isGemini: false,
  );

  group('executeGetAllHistory', () {
    test('returns list of history items from repository', () async {
      when(
        () => mockRepository.getAllHistory(),
      ).thenAnswer((_) async => [testItem]);

      final result = await usecase.executeGetAllHistory();

      expect(result, hasLength(1));
      expect(result.first.word, 'hello');
      expect(result.first.isGemini, false);
    });

    test('calls repository getAllHistory exactly once', () async {
      when(
        () => mockRepository.getAllHistory(),
      ).thenAnswer((_) async => [testItem]);

      await usecase.executeGetAllHistory();

      verify(() => mockRepository.getAllHistory()).called(1);
    });
  });

  group('executeAddHistory', () {
    test('calls repository addHistory with correct entity', () async {
      when(
        () => mockRepository.addHistory(testItem),
      ).thenAnswer((_) async {});

      await usecase.executeAddHistory(testItem);

      verify(() => mockRepository.addHistory(testItem)).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.addHistory(testItem),
      ).thenThrow(Exception('add failed'));

      expect(() => usecase.executeAddHistory(testItem), throwsException);
    });
  });

  group('executeDeleteHistoryItem', () {
    test('calls repository deleteHistoryItem with correct id', () async {
      when(
        () => mockRepository.deleteHistoryItem(1),
      ).thenAnswer((_) async {});

      await usecase.executeDeleteHistoryItem(1);

      verify(() => mockRepository.deleteHistoryItem(1)).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.deleteHistoryItem(99),
      ).thenThrow(Exception('not found'));

      expect(
        () => usecase.executeDeleteHistoryItem(99),
        throwsException,
      );
    });
  });

  group('executeClearHistory', () {
    test('calls repository clearHistory exactly once', () async {
      when(() => mockRepository.clearHistory()).thenAnswer((_) async {});

      await usecase.executeClearHistory();

      verify(() => mockRepository.clearHistory()).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.clearHistory(),
      ).thenThrow(Exception('clear failed'));

      expect(() => usecase.executeClearHistory(), throwsException);
    });
  });
}
