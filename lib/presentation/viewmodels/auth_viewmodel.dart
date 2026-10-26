import 'package:flutter/material.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/domain/entities/auth_entity.dart';
import 'package:translate_app/domain/usecases/auth_usecase.dart';

import '../../data/services/sync_service.dart';
import 'entitlements_viewmodel.dart';
import 'package:translate_app/l10n/l10n.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthUsecase _authUsecase;
  final SyncService _syncService;
  final EntitlementsViewModel _entitlementsViewModel;
  AuthEntity? _user;

  // The account whose plan is loaded; a linked guest keeps its uid.
  String? _planUid;
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
      _user = authUsecase.currentUser,
      _planUid = authUsecase.currentUser?.uid {
    // True only before the listener runs, so signOut() doesn't grant a fresh
    // anonymous quota (resetting the daily limit).
    final noSessionAtStartup = _user == null;

    _authUsecase.user.listen((AuthEntity? user) async {
      _user = user;
      // Another account: never show the last one's plan, even if loading fails.
      if (user?.uid != _planUid) {
        _planUid = user?.uid;
        _entitlementsViewModel.reset();
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
          return l10n.authEmailInUse;
        case 'invalid-email':
          return l10n.authInvalidEmail;
        case 'weak-password':
          return l10n.authWeakPassword;
        case 'user-not-found':
        case 'wrong-password':
          return l10n.authInvalidCredentials;
        case 'network-request-failed':
          return l10n.authNetwork;
        default:
          return e.message;
      }
    }
    String raw = e.toString();
    if (raw.contains('pigeon') ||
        raw.contains('Fire') ||
        raw.contains('fail')) {
      return l10n.authInvalidInput;
    }
    if (raw.contains('FirebaseException') || raw.contains(']')) {
      return raw.split(']').last.trim();
    }
    return raw;
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

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      await _authUsecase.executeSignInWithGoogle();
      // A linked guest keeps its UID, so the auth stream does not fire.
      _user = _authUsecase.currentUser;
      _syncAfterAuth();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e is String ? e : _parseFirebaseError(e));
      return false;
    }
  }

  /// False on failure ([error] set) or when the Apple sheet is closed.
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();
    try {
      final user = await _authUsecase.executeSignInWithApple();
      if (user != null) {
        // A linked guest keeps its UID, so the auth stream does not fire.
        _user = _authUsecase.currentUser;
        _syncAfterAuth();
      }
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setLoading(false);
      _setError(e is String ? e : _parseFirebaseError(e));
      return false;
    }
  }

  /// Deletes the account everywhere and continues as a new guest.
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();
    try {
      await _authUsecase.executeDeleteAccount();
      await _authUsecase.executeSignInAnonymously();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      // Closing the Apple confirmation just stops the deletion.
      if (e is AuthException && (e.code ?? '').contains('cancel')) return false;
      _setError(
        e is NetworkException ? l10n.noInternet : l10n.deleteAccountFailed,
      );
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
}
