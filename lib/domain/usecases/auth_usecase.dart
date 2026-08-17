import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class AuthUsecase {
  final AuthRepository _repository;

  AuthUsecase(this._repository);

  Stream<AuthEntity?> get user => _repository.user;
  AuthEntity? get currentUser => _repository.currentUser;

  Future<AuthEntity?> executeSignIn(String email, String password) =>
      _repository.signInWithEmail(email, password);

  Future<AuthEntity?> executeRegister(String email, String password) =>
      _repository.registerWithEmail(email, password);

  Future<AuthEntity?> executeSignInWithGoogle() =>
      _repository.signInWithGoogle();

  Future<void> executeSignOut() => _repository.signOut();

  Future<void> executeSendEmailVerification() =>
      _repository.sendEmailVerification();

  Future<void> executeReloadUser() => _repository.reloadUser();
}
