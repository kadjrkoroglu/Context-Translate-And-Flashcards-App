import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:translate_app/core/errors/app_exception.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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