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
    // A plan changed elsewhere (another device, App Store settings) shows up on return.
    if (refreshOnResume) {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          if (_entitlements != null && !_isLoading) load();
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

  /// [fromStore]: the server first reads the plan from RevenueCat.
  Future<void> load({bool fromStore = false}) async {
    _checkDevice();
    _setLoading(true);
    _error = null;

    try {
      _entitlements = fromStore
          ? await _usecase.executeRefresh()
          : await _usecase.execute();
      debugPrint(
        '[ENTITLEMENTS] OK tier=${_entitlements!.tier} '
        'maxDecks=${_entitlements!.entitlements.maxDecks} '
        'translateRemaining=${_entitlements!.translateQuota.remaining}',
      );
    } catch (e) {
      debugPrint('[ENTITLEMENTS] FAILED: $e');
      _setError(l10n.failedLoadLimits);
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }
}
