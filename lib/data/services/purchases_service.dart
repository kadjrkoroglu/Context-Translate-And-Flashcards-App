import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// App Store subscriptions through RevenueCat. A signed-in account's RevenueCat
/// id is its Firebase uid, which is how the server's webhook finds the user.
class PurchasesService {
  // Public SDK key from RevenueCat; it is meant to ship inside the app.
  static const _apiKey = 'appl_kgGpWmQeFxQmtfGjbBExXzQEWYv';
  static const _offering = 'default';

  StreamSubscription<User?>? _users;

  Future<void> configure() async {
    final user = FirebaseAuth.instance.currentUser;
    final config = PurchasesConfiguration(_apiKey);
    if (user != null && !user.isAnonymous) config.appUserID = user.uid;
    await Purchases.configure(config);
    // Linking a guest keeps its uid, so only userChanges() reports it.
    _users = FirebaseAuth.instance.userChanges().listen(_followUser);
  }

  Future<void> _followUser(User? user) async {
    try {
      if (user != null && !user.isAnonymous) {
        if (await Purchases.appUserID != user.uid) {
          await Purchases.logIn(user.uid);
        }
      } else if (!await Purchases.isAnonymous) {
        await Purchases.logOut();
      }
    } catch (e) {
      debugPrint('[PURCHASES] user switch failed: $e');
    }
  }

  void onCustomerInfoChanged(VoidCallback listener) =>
      Purchases.addCustomerInfoUpdateListener((_) => listener());

  Future<Offering?> plans() async {
    final offerings = await Purchases.getOfferings();
    return offerings.getOffering(_offering) ?? offerings.current;
  }

  /// Product id → whether Apple would give this person the free trial.
  Future<Map<String, bool>> trialEligibility(List<String> productIds) async {
    final result = await Purchases.checkTrialOrIntroductoryPriceEligibility(
      productIds,
    );
    return {
      for (final entry in result.entries)
        entry.key:
            entry.value.status !=
            IntroEligibilityStatus.introEligibilityStatusIneligible,
    };
  }

  /// False when the App Store sheet was closed without buying.
  Future<bool> buy(Package package) async {
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      return true;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  /// Whether an active subscription came back.
  Future<bool> restore() async =>
      (await Purchases.restorePurchases()).entitlements.active.isNotEmpty;

  /// From RevenueCat's copy on the phone when offline; it knows the expiry date.
  Future<bool> isSubscribed() async =>
      (await Purchases.getCustomerInfo()).entitlements.active.isNotEmpty;

  Future<String?> managementUrl() async =>
      (await Purchases.getCustomerInfo()).managementURL;

  void dispose() => _users?.cancel();
}
