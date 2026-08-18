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

  group('executeSignIn', () {
    test('returns AuthEntity on successful sign in', () async {
      when(
        () => mockRepository.signInWithEmail('test@example.com', '123456'),
      ).thenAnswer((_) async => testUser);

      final result = await usecase.executeSignIn('test@example.com', '123456');

      expect(result, isNotNull);
      expect(result!.uid, 'uid-1');
      expect(result.email, 'test@example.com');
    });

    test('calls repository with correct parameters', () async {
      when(
        () => mockRepository.signInWithEmail('test@example.com', '123456'),
      ).thenAnswer((_) async => testUser);

      await usecase.executeSignIn('test@example.com', '123456');

      verify(
        () => mockRepository.signInWithEmail('test@example.com', '123456'),
      ).called(1);
    });
  });

  group('executeRegister', () {
    test('returns AuthEntity on successful registration', () async {
      when(
        () => mockRepository.registerWithEmail('new@example.com', 'abcdef'),
      ).thenAnswer((_) async => testUser);

      final result = await usecase.executeRegister(
        'new@example.com',
        'abcdef',
      );

      expect(result, isNotNull);
      expect(result!.uid, 'uid-1');
    });

    test('calls repository register method exactly once', () async {
      when(
        () => mockRepository.registerWithEmail('new@example.com', 'abcdef'),
      ).thenAnswer((_) async => testUser);

      await usecase.executeRegister('new@example.com', 'abcdef');

      verify(
        () => mockRepository.registerWithEmail('new@example.com', 'abcdef'),
      ).called(1);
    });
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
      when(() => mockRepository.signInWithGoogle()).thenAnswer(
        (_) async => testUser,
      );

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
      when(() => mockRepository.signOut()).thenThrow(Exception('sign out fail'));

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
