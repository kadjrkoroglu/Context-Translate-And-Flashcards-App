import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
  const guest = AuthEntity(uid: 'u1', emailVerified: false, isAnonymous: true);
  const linked = AuthEntity(uid: 'u1', email: 'a@b.c', emailVerified: true);
  late MockAuthRepository repository;
  late AuthViewModel vm;

  setUp(() {
    repository = MockAuthRepository();
    final sync = MockSyncService();
    // Linking keeps the UID, so the auth stream never fires.
    when(() => repository.user).thenAnswer((_) => const Stream.empty());
    when(() => repository.currentUser).thenReturn(guest);
    when(() => sync.syncAll()).thenAnswer((_) async => null);
    vm = AuthViewModel(
      AuthUsecase(repository),
      sync,
      MockEntitlementsViewModel(),
    );
  });

  test('a guest signing in with Apple shows as signed in', () async {
    expect(vm.isAuthenticated, isFalse);
    when(() => repository.signInWithApple()).thenAnswer((_) async {
      when(() => repository.currentUser).thenReturn(linked);
      return linked;
    });

    expect(await vm.signInWithApple(), isTrue);
    expect(vm.isAuthenticated, isTrue);
  });

  test('a guest signing in with Google shows as signed in', () async {
    when(() => repository.signInWithGoogle()).thenAnswer((_) async {
      when(() => repository.currentUser).thenReturn(linked);
      return linked;
    });

    expect(await vm.signInWithGoogle(), isTrue);
    expect(vm.isAuthenticated, isTrue);
  });

  test('closing the Apple sheet keeps the guest', () async {
    when(() => repository.signInWithApple()).thenAnswer((_) async => null);

    expect(await vm.signInWithApple(), isFalse);
    expect(vm.isAuthenticated, isFalse);
  });
}
