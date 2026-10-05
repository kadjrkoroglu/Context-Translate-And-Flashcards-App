import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/services/sync_service.dart';
import 'package:translate_app/domain/entities/auth_entity.dart';
import 'package:translate_app/domain/repositories/auth_repository.dart';
import 'package:translate_app/domain/usecases/auth_usecase.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSyncService extends ChangeNotifier with Mock implements SyncService {}

class MockEntitlementsViewModel extends ChangeNotifier
    with Mock
    implements EntitlementsViewModel {}

void main() {
  late MockAuthRepository repository;
  late AuthViewModel vm;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.user).thenAnswer((_) => const Stream.empty());
    when(() => repository.currentUser).thenReturn(
      const AuthEntity(uid: 'u1', email: 'a@b.c', emailVerified: true),
    );
    when(() => repository.signInAnonymously()).thenAnswer(
      (_) async => const AuthEntity(
        uid: 'guest',
        emailVerified: false,
        isAnonymous: true,
      ),
    );
    vm = AuthViewModel(
      AuthUsecase(repository),
      MockSyncService(),
      MockEntitlementsViewModel(),
    );
  });

  test('deleting continues as a new guest', () async {
    when(() => repository.deleteAccount()).thenAnswer((_) async {});

    expect(await vm.deleteAccount(), isTrue);

    verifyInOrder([
      () => repository.deleteAccount(),
      () => repository.signInAnonymously(),
    ]);
    expect(vm.error, isNull);
  });

  test('closing the Apple confirmation stops quietly', () async {
    when(() => repository.deleteAccount()).thenThrow(
      const AuthException('Account deletion failed', code: 'canceled'),
    );

    expect(await vm.deleteAccount(), isFalse);

    expect(vm.error, isNull);
    verifyNever(() => repository.signInAnonymously());
  });

  test('offline: the account stays and the reason is shown', () async {
    when(
      () => repository.deleteAccount(),
    ).thenThrow(const NetworkException('offline'));

    expect(await vm.deleteAccount(), isFalse);

    expect(vm.error, 'No internet connection.');
    verifyNever(() => repository.signInAnonymously());
  });
}
