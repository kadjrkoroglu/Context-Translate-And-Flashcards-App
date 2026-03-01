import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

import '../../data/services/sync_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SyncService _syncService;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthViewModel(this._authRepository, this._syncService) {
    _authRepository.user.listen((User? user) async {
      final bool isLogin = user != null && _user == null;

      _user = user;

      if (user != null && !user.emailVerified) {
        user.reload().then((_) {
          _user = _authRepository.currentUser;
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

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Directly check the current firebase user for the most up-to-date status
  bool get isEmailVerified => _user?.emailVerified ?? false;

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      await _authRepository.signInWithEmail(email, password);
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
      await _authRepository.registerWithEmail(email, password);

      // Wait for Firebase to settle, then force a reload to get fresh verification status
      await Future.delayed(const Duration(milliseconds: 500));
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        _user = _authRepository.currentUser;
      }

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
      await _authRepository.signInWithGoogle();
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
      await _authRepository.signOut();
      _setLoading(false);
    } catch (e) {
      _setError(e);
      _setLoading(false);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> reloadUser() async {
    try {
      await _authRepository.reloadUser();
      final freshUser = _authRepository.currentUser;
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
