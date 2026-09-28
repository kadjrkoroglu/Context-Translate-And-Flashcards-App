import 'package:flutter/material.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/domain/usecases/entitlements_usecase.dart';

class EntitlementsViewModel extends ChangeNotifier {
  final EntitlementsUsecase _usecase;

  EntitlementsViewModel(this._usecase);

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

  Future<void> load() async {
    _setLoading(true);
    _error = null;

    try {
      _entitlements = await _usecase.execute();
      debugPrint(
        '[ENTITLEMENTS] OK tier=${_entitlements!.tier} '
        'maxDecks=${_entitlements!.entitlements.maxDecks} '
        'translateRemaining=${_entitlements!.translateQuota.remaining}',
      );
    } catch (e) {
      debugPrint('[ENTITLEMENTS] FAILED: $e');
      _setError('Failed to load account limits');
    } finally {
      _setLoading(false);
    }
  }
}
