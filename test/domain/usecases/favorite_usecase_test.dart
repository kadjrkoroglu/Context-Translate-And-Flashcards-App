import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/domain/entities/favorite_word_entity.dart';
import 'package:translate_app/domain/repositories/favorite_repository.dart';
import 'package:translate_app/domain/usecases/favorite_usecase.dart';

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

void main() {
  late MockFavoriteRepository mockRepository;
  late FavoriteUsecase usecase;

  setUp(() {
    mockRepository = MockFavoriteRepository();
    usecase = FavoriteUsecase(mockRepository);
  });

  final testFavorite = FavoriteWordEntity(
    id: 1,
    syncId: 'fav-sync-1',
    word: 'hello',
    translation: 'merhaba',
    createdAt: DateTime(2025),
    lastModified: DateTime(2025),
    isGemini: true,
  );

  group('executeGetAllFavorites', () {
    test('returns list of favorites from repository', () async {
      when(
        () => mockRepository.getAllFavorites(),
      ).thenAnswer((_) async => [testFavorite]);

      final result = await usecase.executeGetAllFavorites();

      expect(result, hasLength(1));
      expect(result.first.word, 'hello');
      expect(result.first.isGemini, true);
    });

    test('returns empty list when no favorites exist', () async {
      when(
        () => mockRepository.getAllFavorites(),
      ).thenAnswer((_) async => []);

      final result = await usecase.executeGetAllFavorites();

      expect(result, isEmpty);
    });

    test('calls repository getAllFavorites exactly once', () async {
      when(
        () => mockRepository.getAllFavorites(),
      ).thenAnswer((_) async => [testFavorite]);

      await usecase.executeGetAllFavorites();

      verify(() => mockRepository.getAllFavorites()).called(1);
    });
  });

  group('executeAddFavorite', () {
    test('calls repository addFavorite with correct entity', () async {
      when(
        () => mockRepository.addFavorite(testFavorite),
      ).thenAnswer((_) async {});

      await usecase.executeAddFavorite(testFavorite);

      verify(() => mockRepository.addFavorite(testFavorite)).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.addFavorite(testFavorite),
      ).thenThrow(Exception('add failed'));

      expect(() => usecase.executeAddFavorite(testFavorite), throwsException);
    });
  });

  group('executeDeleteFavorite', () {
    test('calls repository deleteFavorite with correct id', () async {
      when(() => mockRepository.deleteFavorite(1)).thenAnswer((_) async {});

      await usecase.executeDeleteFavorite(1);

      verify(() => mockRepository.deleteFavorite(1)).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.deleteFavorite(99),
      ).thenThrow(Exception('not found'));

      expect(() => usecase.executeDeleteFavorite(99), throwsException);
    });
  });
}
