import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:translate_app/domain/entities/auth_entity.dart';
import 'package:translate_app/domain/usecases/auth_usecase.dart';

import '../../data/services/sync_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthUsecase _authUsecase;
  final SyncService _syncService;
  AuthEntity? _user;
  bool _isLoading = false;
  String? _error;

  AuthViewModel(this._authUsecase, this._syncService) {
    _authUsecase.user.listen((AuthEntity? user) async {
      final bool isLogin = user != null && _user == null;

      _user = user;

      if (user != null && !user.emailVerified) {
        _authUsecase.executeReloadUser().then((_) {
          _user = _authUsecase.currentUser;
          notifyListeners();
        });
      }
      notifyListeners();

      // Run sync operations after UI is updated
      if (isLogin) {
        try {
          await _syncService.syncAll();
        } catch (e) {
          debugPrint('Sync on login failed: $e');
        }
      }
    });
  }

  AuthEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Directly check the current firebase user for the most up-to-date status
  bool get isEmailVerified => _user?.emailVerified ?? false;

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      await _authUsecase.executeSignIn(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _setError('Please enter a valid email address.');
      return false;
    }
    if (password != confirmPassword) {
      _setError('Passwords do not match.');
      return false;
    }

    _setLoading(true);
    clearError();
    try {
      await _authUsecase.executeRegister(email, password);

      // Wait for Firebase to settle, then force a reload to get fresh verification status
      await Future.delayed(const Duration(milliseconds: 500));
      await _authUsecase.executeReloadUser();
      _user = _authUsecase.currentUser;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    clearError();
    try {
      await _authUsecase.executeSignInWithGoogle();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authUsecase.executeSignOut();
      _setLoading(false);
    } catch (e) {
      _setError(e);
      _setLoading(false);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authUsecase.executeSendEmailVerification();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> reloadUser() async {
    try {
      await _authUsecase.executeReloadUser();
      final freshUser = _authUsecase.currentUser;
      if (freshUser != null) {
        _user = freshUser;
        notifyListeners();
      }
    } catch (e) {
      _setError(e);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(dynamic e) {
    _isLoading = false;
    String message = 'An unexpected error occurred.';

    if (e is String) {
      message = e;
    } else if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email is already registered.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password too weak (min 6 chars).';
          break;
        case 'user-not-found':
        case 'wrong-password':
          message = 'Invalid email or password.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your connection.';
          break;
        default:
          message = e.message ?? 'Authentication failed.';
      }
    } else {
      // Clean up technical platform strings (like pigeon errors)
      String raw = e.toString();
      if (raw.contains('pigeon') ||
          raw.contains('Fire') ||
          raw.contains('fail')) {
        message = 'Invalid input. Please check your details.';
      } else {
        message = raw;
      }
    }

    // Double check to ensure no technical prefixes
    if (message.contains('FirebaseException') || message.contains(']')) {
      message = message.split(']').last.trim();
    }

    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
