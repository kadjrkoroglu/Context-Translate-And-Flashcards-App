import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/domain/usecases/entitlements_usecase.dart';
import 'package:translate_app/l10n/l10n.dart';

class EntitlementsViewModel extends ChangeNotifier {
  final EntitlementsUsecase _usecase;

  EntitlementsViewModel(
    this._usecase, {
    Future<bool> Function()? isSubscribed,
    bool refreshOnResume = false,
  }) : _isSubscribed = isSubscribed {
    _checkDevice();
    // A plan changed elsewhere (another device, App Store settings) shows up
    // on return, and a failed load is tried again.
    if (refreshOnResume) {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          if (!_isLoading) load();
        },
      );
    }
  }

  final Future<bool> Function()? _isSubscribed;
  AppLifecycleListener? _lifecycle;
  bool _subscribedOnDevice = false;

  /// An active App Store subscription on this phone, known even offline.
  bool get subscribedOnDevice => _subscribedOnDevice;

  Future<void> _checkDevice() async {
    final check = _isSubscribed;
    if (check == null) return;
    try {
      final subscribed = await check();
      if (subscribed == _subscribedOnDevice) return;
      _subscribedOnDevice = subscribed;
      notifyListeners();
    } catch (e) {
      debugPrint('[ENTITLEMENTS] subscription check failed: $e');
    }
  }

  EntitlementsEntity? _entitlements;
  bool _isLoading = false;
  String? _error;

  EntitlementsEntity? get entitlements => _entitlements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AppTier get tier => _entitlements?.tier ?? AppTier.free;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  // Only the newest load's answer counts.
  int _loads = 0;

  /// Forgets the plan of an account that just left.
  void reset() {
    _loads++;
    _entitlements = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// [fromStore]: the server first reads the plan from RevenueCat.
  Future<void> load({bool fromStore = false}) async {
    final load = ++_loads;
    _checkDevice();
    _setLoading(true);
    _error = null;

    try {
      final entitlements = fromStore
          ? await _usecase.executeRefresh()
          : await _usecase.execute();
      if (load != _loads) return;
      _entitlements = entitlements;
      debugPrint(
        '[ENTITLEMENTS] OK tier=${_entitlements!.tier} '
        'maxDecks=${_entitlements!.entitlements.maxDecks} '
        'translateRemaining=${_entitlements!.translateQuota.remaining}',
      );
    } catch (e) {
      if (load != _loads) return;
      debugPrint('[ENTITLEMENTS] FAILED: $e');
      _setError(l10n.failedLoadLimits);
    } finally {
      if (load == _loads) _setLoading(false);
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }
}
