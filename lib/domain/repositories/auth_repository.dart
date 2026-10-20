import '../entities/auth_entity.dart';

abstract class AuthRepository {
  Stream<AuthEntity?> get user;
  AuthEntity? get currentUser;

  Future<AuthEntity?> signInWithGoogle();
  Future<AuthEntity?> signInWithApple();
  Future<void> deleteAccount();
  Future<AuthEntity?> signInAnonymously();
  Future<void> signOut();
}
