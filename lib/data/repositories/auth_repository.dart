import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  // Auth state changes stream
  Stream<User?> get user => _authService.user;
  User? get currentUser => _authService.currentUser;

  // Sign in with Email & Password
  Future<UserCredential?> signInWithEmail(String email, String password) =>
      _authService.signInWithEmail(email, password);

  // Register with Email & Password
  Future<UserCredential?> registerWithEmail(String email, String password) =>
      _authService.registerWithEmail(email, password);

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() => _authService.signInWithGoogle();

  // Sign out
  Future<void> signOut() => _authService.signOut();

  // Email verification
  Future<void> sendEmailVerification() => _authService.sendEmailVerification();

  // Reload user
  Future<void> reloadUser() => _authService.reloadUser();
}
