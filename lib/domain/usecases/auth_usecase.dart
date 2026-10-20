import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class AuthUsecase {
  final AuthRepository _repository;

  AuthUsecase(this._repository);

  Stream<AuthEntity?> get user => _repository.user;
  AuthEntity? get currentUser => _repository.currentUser;

  Future<AuthEntity?> executeSignInWithGoogle() =>
      _repository.signInWithGoogle();

  Future<AuthEntity?> executeSignInWithApple() =>
      _repository.signInWithApple();

  Future<void> executeDeleteAccount() => _repository.deleteAccount();

  Future<AuthEntity?> executeSignInAnonymously() =>
      _repository.signInAnonymously();

  Future<void> executeSignOut() => _repository.signOut();
}
