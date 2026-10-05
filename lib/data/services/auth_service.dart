import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/data/services/account_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AccountService _account;

  AuthService({AccountService? account})
    : _account = account ?? AccountService();

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException('Authentication failed', details: e.message, code: e.code);
    }
  }

  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      final anonymousUser = _auth.currentUser;
      final UserCredential credential;
      if (anonymousUser != null && anonymousUser.isAnonymous) {
        // Upgrade the guest session in place so its Firebase UID (and every
        // row keyed by it, both here and in our backend) is kept as-is.
        credential = await anonymousUser.linkWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
      } else {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      if (credential.user != null) {
        await credential.user!.sendEmailVerification();
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException('Registration failed', details: e.message, code: e.code);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        'Failed to send verification email',
        details: e.message,
        code: e.code,
      );
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthException('Failed to reload user', details: e.message, code: e.code);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final anonymousUser = _auth.currentUser;
      if (anonymousUser != null && anonymousUser.isAnonymous) {
        try {
          // Same reasoning as registerWithEmail: keep the guest's UID.
          return await anonymousUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          // This Google account already has a real account elsewhere; sign
          // into that one instead and let the throwaway guest session go.
          if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
            return await _auth.signInWithCredential(credential);
          }
          rethrow;
        }
      }

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException('Google sign-in failed', details: e.message, code: e.code);
    } on PlatformException catch (e) {
      throw AuthException('Google sign-in failed', details: e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw GeneralException('Google sign-in failed', details: e.toString());
    }
  }

  /// Returns null if the user closes the Apple sheet.
  Future<UserCredential?> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    try {
      final anonymousUser = _auth.currentUser;
      if (anonymousUser != null && anonymousUser.isAnonymous) {
        try {
          // Same as Google: keep the guest's UID.
          return await anonymousUser.linkWithProvider(provider);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            final credential = e.credential;
            return credential != null
                ? await _auth.signInWithCredential(credential)
                : await _auth.signInWithProvider(provider);
          }
          rethrow;
        }
      }
      return await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      if (_isCancel(e.code)) return null;
      throw AuthException(
        'Apple sign-in failed',
        details: e.message,
        code: e.code,
      );
    } on PlatformException catch (e) {
      if (_isCancel(e.code)) return null;
      throw AuthException(
        'Apple sign-in failed',
        details: e.message,
        code: e.code,
      );
    }
  }

  static bool _isCancel(String code) => code.toLowerCase().contains('cancel');

  /// Apple users confirm again so its token can be revoked; the server deletes the rest.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      if (user.providerData.any((p) => p.providerId == 'apple.com')) {
        final credential = await user.reauthenticateWithProvider(
          AppleAuthProvider(),
        );
        final code = credential.additionalUserInfo?.authorizationCode;
        if (code != null) {
          await _auth.revokeTokenWithAuthorizationCode(code).catchError((e) {
            // Deletion goes ahead: a revoke error must not trap the user.
            debugPrint('Apple token revoke failed: $e');
          });
        }
      }
      await _account.deleteAccount();
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        'Account deletion failed',
        details: e.message,
        code: e.code,
      );
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw AuthException('Anonymous sign-in failed', details: e.message, code: e.code);
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      if (e is AppException) rethrow;
      throw GeneralException('Failed to sign out', details: e.toString());
    }
  }
}