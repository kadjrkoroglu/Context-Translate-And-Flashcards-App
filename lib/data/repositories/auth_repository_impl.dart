import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Stream<AuthEntity?> get user => _authService.user.map(_toEntity);

  @override
  AuthEntity? get currentUser => _toEntity(_authService.currentUser);

  @override
  Future<AuthEntity?> signInWithEmail(String email, String password) async {
    final credential = await _authService.signInWithEmail(email, password);
    return _toEntity(credential?.user);
  }

  @override
  Future<AuthEntity?> registerWithEmail(String email, String password) async {
    final credential = await _authService.registerWithEmail(email, password);
    return _toEntity(credential?.user);
  }

  @override
  Future<AuthEntity?> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    return _toEntity(credential?.user);
  }

  @override
  Future<void> signOut() => _authService.signOut();

  @override
  Future<void> sendEmailVerification() => _authService.sendEmailVerification();

  @override
  Future<void> reloadUser() => _authService.reloadUser();

  AuthEntity? _toEntity(User? user) {
    if (user == null) return null;
    return AuthEntity(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }
}
