import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:translate_app/data/services/purchases_service.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';

enum PlanOption { standard, premium }

enum PurchaseOutcome { done, cancelled, failed }

enum RestoreOutcome { restored, nothing, failed }

/// The plans from the App Store (prices, trial) and buying or restoring them.
class SubscriptionViewModel extends ChangeNotifier {
  final PurchasesService _purchases;
  final EntitlementsViewModel _entitlements;

  SubscriptionViewModel(this._purchases, this._entitlements) {
    // Renewals, expiries and purchases on another device reach the app here.
    _purchases.onCustomerInfoChanged(() => _entitlements.load(fromStore: true));
  }

  static const _packageIds = {
    PlanOption.standard: 'standard_monthly',
    PlanOption.premium: 'premium_monthly',
  };

  Map<PlanOption, Package> _packages = {};
  Map<String, bool> _trialEligible = {};
  bool _loading = false;
  bool _loadFailed = false;
  bool _busy = false;
  // Asked for here, before the server hears of it from RevenueCat.
  bool _askedForStandard = false;

  bool get isLoading => _loading;
  bool get loadFailed => _loadFailed;

  /// A purchase or restore is running.
  bool get isBusy => _busy;

  Package? packageOf(PlanOption plan) => _packages[plan];

  bool get _onPremium => switch (_entitlements.tier) {
    AppTier.premium || AppTier.trialPremium => true,
    _ => false,
  };

  /// Premium moves down to Standard when the paid period ends; null if not.
  /// The date may be unknown right after asking.
  ({DateTime? at})? get standardSwitch {
    if (!_onPremium) return null;
    final pending = _entitlements.entitlements?.pendingSwitch;
    final at = pending?.at;
    if (pending?.plan == AppTier.standard &&
        (at == null || at.isAfter(DateTime.now()))) {
      return (at: at);
    }
    return _askedForStandard ? (at: null) : null;
  }

  /// Formatted by the App Store in the local currency.
  String? priceOf(PlanOption plan) => _packages[plan]?.storeProduct.priceString;

  /// Length of the free trial in days; null if the product has none.
  int? trialDaysOf(PlanOption plan) {
    final intro = _packages[plan]?.storeProduct.introductoryPrice;
    if (intro == null || intro.price > 0) return null;
    final unitDays = switch (intro.periodUnit) {
      PeriodUnit.day => 1,
      PeriodUnit.week => 7,
      PeriodUnit.month => 30,
      PeriodUnit.year => 365,
      PeriodUnit.unknown => 0,
    };
    final days = intro.periodNumberOfUnits * unitDays;
    return days > 0 ? days : null;
  }

  /// Apple gives one trial per subscription group and Apple ID.
  bool trialAvailable(PlanOption plan) =>
      trialDaysOf(plan) != null &&
      (_trialEligible[_packages[plan]!.storeProduct.identifier] ?? true);

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      final offering = await _purchases.plans();
      // A plain loop: isar_generator's parser can't read null-aware map entries.
      final packages = <PlanOption, Package>{};
      for (final entry in _packageIds.entries) {
        final package = offering?.getPackage(entry.value);
        if (package != null) packages[entry.key] = package;
      }
      _packages = packages;
      _loadFailed = _packages.length != _packageIds.length;
      if (!_loadFailed) {
        _trialEligible = await _purchases.trialEligibility([
          for (final package in _packages.values)
            package.storeProduct.identifier,
        ]);
      }
    } catch (e) {
      debugPrint('[PURCHASES] plans failed: $e');
      _loadFailed = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<PurchaseOutcome> buy(PlanOption plan) async {
    final package = _packages[plan];
    if (package == null || _busy) return PurchaseOutcome.failed;
    final downgrade = plan == PlanOption.standard && _onPremium;
    _setBusy(true);
    try {
      if (!await _purchases.buy(package)) return PurchaseOutcome.cancelled;
      if (downgrade) _askedForStandard = true;
      await _entitlements.load(fromStore: true);
      return PurchaseOutcome.done;
    } catch (e) {
      debugPrint('[PURCHASES] purchase failed: $e');
      return PurchaseOutcome.failed;
    } finally {
      _setBusy(false);
    }
  }

  Future<RestoreOutcome> restore() async {
    if (_busy) return RestoreOutcome.failed;
    _setBusy(true);
    try {
      final found = await _purchases.restore();
      await _entitlements.load(fromStore: true);
      return found ? RestoreOutcome.restored : RestoreOutcome.nothing;
    } catch (e) {
      debugPrint('[PURCHASES] restore failed: $e');
      return RestoreOutcome.failed;
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> managementUrl() async {
    try {
      return await _purchases.managementUrl();
    } catch (_) {
      return null;
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
