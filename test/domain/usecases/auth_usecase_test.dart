import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/domain/entities/auth_entity.dart';
import 'package:translate_app/domain/repositories/auth_repository.dart';
import 'package:translate_app/domain/usecases/auth_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthUsecase usecase;

  const testUser = AuthEntity(
    uid: 'uid-1',
    email: 'test@example.com',
    displayName: 'Test User',
    emailVerified: true,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = AuthUsecase(mockRepository);
  });

  group('executeSignInWithGoogle', () {
    test('returns AuthEntity on Google sign in', () async {
      when(() => mockRepository.signInWithGoogle()).thenAnswer(
        (_) async => const AuthEntity(
          uid: 'google-uid',
          email: 'google@test.com',
          emailVerified: true,
        ),
      );

      final result = await usecase.executeSignInWithGoogle();

      expect(result, isNotNull);
      expect(result!.uid, 'google-uid');
    });

    test('calls repository signInWithGoogle exactly once', () async {
      when(
        () => mockRepository.signInWithGoogle(),
      ).thenAnswer((_) async => testUser);

      await usecase.executeSignInWithGoogle();

      verify(() => mockRepository.signInWithGoogle()).called(1);
    });
  });

  group('executeSignOut', () {
    test('calls repository signOut exactly once', () async {
      when(() => mockRepository.signOut()).thenAnswer((_) async {});

      await usecase.executeSignOut();

      verify(() => mockRepository.signOut()).called(1);
    });

    test('propagates exceptions from repository', () async {
      when(
        () => mockRepository.signOut(),
      ).thenThrow(Exception('sign out fail'));

      expect(() => usecase.executeSignOut(), throwsException);
    });
  });

  group('currentUser', () {
    test('returns currentUser from repository', () {
      when(() => mockRepository.currentUser).thenReturn(testUser);

      final result = usecase.currentUser;

      expect(result, equals(testUser));
    });

    test('returns null when no user is signed in', () {
      when(() => mockRepository.currentUser).thenReturn(null);

      final result = usecase.currentUser;

      expect(result, isNull);
    });
  });
}
