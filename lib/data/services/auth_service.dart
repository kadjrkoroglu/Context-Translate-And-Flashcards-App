import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
          // Keep the guest's UID, so its rows here and on the server stay.
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
    final rawNonce = _nonce();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw AuthException(
        'Apple sign-in failed',
        details: e.message,
        code: e.code.name,
      );
    }
    final idToken = apple.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple sign-in failed', code: 'missing-token');
    }
    final credential = AppleAuthProvider.credentialWithIDToken(
      idToken,
      rawNonce,
      AppleFullPersonName(
        givenName: apple.givenName,
        familyName: apple.familyName,
      ),
    );
    try {
      final result = await _linkGuestOrSignIn(credential);
      // Apple sends the name only the first time; Firebase doesn't keep it on a link.
      final name = [
        apple.givenName,
        apple.familyName,
      ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
      final user = result.user;
      if (user != null && name.isNotEmpty && (user.displayName ?? '').isEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      return result;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        'Apple sign-in failed',
        details: e.message,
        code: e.code,
      );
    }
  }

  // Same as Google: a guest keeps its UID.
  Future<UserCredential> _linkGuestOrSignIn(AuthCredential credential) async {
    final anonymousUser = _auth.currentUser;
    if (anonymousUser == null || !anonymousUser.isAnonymous) {
      return _auth.signInWithCredential(credential);
    }
    try {
      return await anonymousUser.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      final existing = e.credential;
      if ((e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') &&
          existing != null) {
        return _auth.signInWithCredential(existing);
      }
      rethrow;
    }
  }

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

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