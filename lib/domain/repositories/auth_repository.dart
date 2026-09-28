import '../entities/auth_entity.dart';

abstract class AuthRepository {
  Stream<AuthEntity?> get user;
  AuthEntity? get currentUser;

  Future<AuthEntity?> signInWithEmail(String email, String password);
  Future<AuthEntity?> registerWithEmail(String email, String password);
  Future<AuthEntity?> signInWithGoogle();
  Future<AuthEntity?> signInAnonymously();
  Future<void> signOut();
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
}
