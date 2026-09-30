import 'package:flutter/material.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/domain/entities/auth_entity.dart';
import 'package:translate_app/domain/usecases/auth_usecase.dart';

import '../../data/services/sync_service.dart';
import 'entitlements_viewmodel.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthUsecase _authUsecase;
  final SyncService _syncService;
  final EntitlementsViewModel _entitlementsViewModel;
  AuthEntity? _user;
  bool _isLoading = false;
  String? _error;

  AuthViewModel(
    AuthUsecase authUsecase,
    SyncService syncService,
    EntitlementsViewModel entitlementsViewModel,
  ) : _authUsecase = authUsecase,
      _syncService = syncService,
      _entitlementsViewModel = entitlementsViewModel,
      // Seed the session so a cold-start restore isn't treated as a login.
      _user = authUsecase.currentUser {
    // True only before the listener runs, so signOut() doesn't grant a fresh
    // anonymous quota (resetting the daily limit).
    final noSessionAtStartup = _user == null;

    _authUsecase.user.listen((AuthEntity? user) async {
      _user = user;

      // Reload a restored account that hasn't verified its email yet.
      if (user != null && !user.isAnonymous && !user.emailVerified) {
        _authUsecase.executeReloadUser().then((_) {
          _user = _authUsecase.currentUser;
          notifyListeners();
        });
      }
      // Refresh tier/quota on login and cold-start restore.
      if (user != null) _entitlementsViewModel.load();
      notifyListeners();
    });

    // First launch: anonymous sign-in so free-tier features work without an
    // account. Not repeated after signOut().
    if (noSessionAtStartup) {
      _authUsecase.executeSignInAnonymously().catchError((e) {
        debugPrint('Anonymous sign-in failed: $e');
        return null;
      });
    }
  }

  AuthEntity? get user => _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  // Guest (anonymous) sessions don't count as a real account.
  bool get isAuthenticated => _user != null && !_user!.isAnonymous;

  bool get isEmailVerified => _user?.emailVerified ?? false;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseFirebaseError(dynamic e) {
    if (e is AuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password too weak (min 6 chars).';
        case 'user-not-found':
        case 'wrong-password':
          return 'Invalid email or password.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        default:
          return e.message;
      }
    }
    String raw = e.toString();
    if (raw.contains('pigeon') ||
        raw.contains('Fire') ||
        raw.contains('fail')) {
      return 'Invalid input. Please check your details.';
    }
    if (raw.contains('FirebaseException') || raw.contains(']')) {
      return raw.split(']').last.trim();
    }
    return raw;
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authUsecase.executeSignIn(email, password);
      _syncAfterAuth();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e is String ? e : _parseFirebaseError(e));
      return false;
    }
  }

  // Sync only on an explicit login, never on a cold-start restore.
  void _syncAfterAuth() {
    _syncService
        .syncAll()
        .then((authError) {
          if (authError != null) debugPrint('Sync after auth: $authError');
        })
        .catchError((e) {
          debugPrint('Sync after auth failed: $e');
        });
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
    _clearError();
    try {
      await _authUsecase.executeRegister(email, password);

      await Future.delayed(const Duration(milliseconds: 500));
      await _authUsecase.executeReloadUser();
      _user = _authUsecase.currentUser;

      _syncAfterAuth();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e is String ? e : _parseFirebaseError(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      await _authUsecase.executeSignInWithGoogle();
      _syncAfterAuth();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e is String ? e : _parseFirebaseError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authUsecase.executeSignOut();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(_parseFirebaseError(e));
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authUsecase.executeSendEmailVerification();
    } catch (e) {
      _setError(_parseFirebaseError(e));
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
      _setError(_parseFirebaseError(e));
    }
  }
}
