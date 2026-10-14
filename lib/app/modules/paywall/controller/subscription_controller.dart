import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/internet_connectivity_service.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/connection_interrupted_dialog.dart';
import '../services/revenue_cat_service.dart';
import '../services/user_credits_manager.dart';
import 'credits_controller.dart';

/// Fetches subscription products and keeps [isUserPro] in sync with RevenueCat.
class SubscriptionController extends GetxController {
  final isUserPro = false.obs;
  final isLoadingProducts = true.obs;

  final _revenueCatHelper = RevenueCatHelper();
  final products = <StoreProduct>[].obs;

  bool get isPro => isUserPro.value;

  Future<void>? _syncTask;

  /// Set once the store or cached fallback has answered.
  bool _synced = false;

  @override
  void onInit() {
    super.onInit();
    _revenueCatHelper.addListener(_onEntitlementChanged);
    _fetchProducts();
    _seedFromCache();
    _syncTask = syncProStatus();
  }

  Future<void> _seedFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(UserCreditsManager.proStatusKey) ?? false;
    if (!_synced) isUserPro.value = cached;
  }

  Future<void> awaitSync() => _syncTask ?? syncProStatus();

  Future<void> syncProStatus() async {
    final proViaRevenueCat = await _revenueCatHelper.checkSubscriptionStatus();

    if (proViaRevenueCat == null) {
      isUserPro.value = await UserCreditsManager().isPro();
      _synced = true;
      return;
    }

    _synced = true;
    isUserPro.value = proViaRevenueCat;

    if (!proViaRevenueCat) await _downgradeIfLapsed();
  }

  void _onEntitlementChanged(bool isPro) {
    _synced = true;
    isUserPro.value = isPro;

    if (!isPro) unawaited(_downgradeIfLapsed());
  }

  Future<void> _downgradeIfLapsed() async {
    if (!await UserCreditsManager().isPro()) return;

    await UserCreditsManager().downgradeToFree();
    CreditsController.bump();

    log(
      'Subscription lapsed — downgraded to free tier '
      '(restored pre-Pro balance)',
      name: 'SubscriptionController',
    );
  }

  Future<void>? _fetchTask;

  Future<void> _fetchProducts() =>
      _fetchTask ??= _doFetchProducts().whenComplete(() => _fetchTask = null);

  Future<void> _doFetchProducts() async {
    isLoadingProducts.value = true;

    try {
      final fetched = await _revenueCatHelper.getProducts();

      // Keep previously loaded products if this attempt returned empty.
      if (fetched.isNotEmpty) products.value = fetched;
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<bool> retryFetch() async {
    await _fetchProducts();
    return products.isNotEmpty;
  }

  StoreProduct? productFor(String productId) => products.firstWhereOrNull(
    (p) => RevenueCatHelper.productIdOf(p.identifier) == productId,
  );

  /// Buys a subscription after checking internet access.
  Future<bool> buy(
    BuildContext context, {
    required String productId,
    required String plan,
    required String source,
  }) async {
    AnalyticsService.logPaywallPurchaseTapped(plan, source);

    if (!RevenueCatHelper.isConfigured) {
      AnalyticsService.logPaywallPurchaseFailed(
        plan,
        'store_unavailable',
        source,
      );
      _storeUnavailable();
      return false;
    }

    // Check actual internet access before starting the purchase.
    final hasInternet = await InternetConnectivityService.hasInternetAccess();

    if (!hasInternet) {
      AnalyticsService.logPaywallPurchaseFailed(
        plan,
        'offline_connection_error',
        source,
      );

      await showConnectionInterruptedDialog();
      return false;
    }

    // Products may not have loaded when the app was offline at launch.
    if (productFor(productId) == null) await retryFetch();

    final product = productFor(productId);

    if (product == null) {
      AnalyticsService.logPaywallPurchaseFailed(
        plan,
        'product_unavailable',
        source,
      );
      _storeUnavailable();
      return false;
    }

    // Already subscribed: unlock instead of purchasing again.
    if (await _revenueCatHelper.checkSubscriptionStatus() == true) {
      isUserPro.value = true;

      AnalyticsService.logPaywallRestored(restored: true, source: source);

      showAppSnackbar(
        'paywall_controller_purchase_restored_title'.tr,
        'paywall_controller_purchase_restored_message'.tr,
      );

      return true;
    }

    if (!context.mounted) return false;

    final callback = _PurchaseCallback(
      controller: this,
      plan: plan,
      source: source,
    );

    unawaited(_revenueCatHelper.buyProduct(product, callback, context));

    return callback.result;
  }

  /// Restores a subscription after checking internet access.
  Future<bool> restorePurchase(
    BuildContext context, {
    required String source,
  }) async {
    AnalyticsService.logPaywallRestoreTapped(source);

    if (!RevenueCatHelper.isConfigured) {
      AnalyticsService.logPaywallRestoreFailed(source);
      _storeUnavailable();
      return false;
    }

    // Check actual internet access before starting the restore.
    final hasInternet = await InternetConnectivityService.hasInternetAccess();

    if (!hasInternet) {
      AnalyticsService.logPaywallRestoreFailed(source);

      await showConnectionInterruptedDialog();
      return false;
    }

    if (!context.mounted) return false;

    final callback = _PurchaseCallback(
      controller: this,
      plan: null,
      source: source,
    );

    unawaited(_revenueCatHelper.restorePurchases(context, callback));

    return callback.result;
  }
}

void _storeUnavailable() => showAppSnackbar(
  'paywall_controller_store_unavailable_title'.tr,
  'paywall_controller_store_unavailable_message'.tr,
);

class _PurchaseCallback implements InAppCallback {
  _PurchaseCallback({
    required this.controller,
    required this.plan,
    required this.source,
  });

  final SubscriptionController controller;

  /// The plan being purchased, or null for a restore.
  final String? plan;
  final String source;

  final _result = Completer<bool>();
  Future<bool> get result => _result.future;

  bool _restoringOwned = false;

  void _complete(bool unlocked) {
    if (!_result.isCompleted) _result.complete(unlocked);
  }

  @override
  void onPurchaseSuccess(BuildContext context) {
    controller.isUserPro.value = true;

    AnalyticsService.logPaywallPurchased(plan ?? 'unknown', source);
    _complete(true);
  }

  @override
  void onPurchaseCancelled(BuildContext context) {
    AnalyticsService.logPaywallPurchaseCancelled(plan ?? 'unknown', source);

    _complete(false);
  }

  @override
  void onPurchaseFailure(BuildContext context, PurchasesErrorCode code) {
    AnalyticsService.logPaywallPurchaseFailed(
      plan ?? 'unknown',
      code.name,
      source,
    );

    switch (code) {
      case PurchasesErrorCode.paymentPendingError:
        showAppSnackbar(
          'paywall_controller_purchase_pending_title'.tr,
          'paywall_controller_purchase_pending_message'.tr,
        );
        break;

      case PurchasesErrorCode.productAlreadyPurchasedError:
        _restoringOwned = true;
        controller._revenueCatHelper.restorePurchases(context, this);
        return;

      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        // Connection dropped after the initial connectivity check.
        unawaited(showConnectionInterruptedDialog());
        break;

      default:
        showAppSnackbar(
          'paywall_controller_purchase_failed_title'.tr,
          'paywall_controller_try_again_message'.tr,
        );
        break;
    }

    _complete(false);
  }

  @override
  void onPurchasedRestored(BuildContext context) async {
    controller.isUserPro.value =
        await controller._revenueCatHelper.checkSubscriptionStatus() ?? true;

    final restored = controller.isUserPro.value;

    if (_restoringOwned && restored) {
      AnalyticsService.logPaywallRestored(restored: true, source: source);
    }

    if (!_restoringOwned) {
      AnalyticsService.logPaywallRestored(restored: restored, source: source);

      if (restored) {
        showAppSnackbar(
          'paywall_controller_purchase_restored_title'.tr,
          'paywall_controller_purchase_restored_message'.tr,
        );
      } else {
        _nothingToRestore();
      }
    } else if (!restored) {
      _alreadyOwned();
    }

    _complete(restored);
  }

  @override
  void onPurchaseExpired(BuildContext context) {
    if (_restoringOwned) {
      _alreadyOwned();
    } else {
      AnalyticsService.logPaywallRestored(restored: false, source: source);
      _nothingToRestore();
    }

    _complete(false);
  }

  @override
  void onPurchaseRestoreFailed(BuildContext context) {
    if (_restoringOwned) {
      log('restore after already-owned failed', name: 'SubscriptionController');
      _alreadyOwned();
    } else {
      AnalyticsService.logPaywallRestoreFailed(source);

      showAppSnackbar(
        'paywall_controller_restore_failed_title'.tr,
        'paywall_controller_try_again_message'.tr,
      );
    }

    _complete(false);
  }

  void _nothingToRestore() => showAppSnackbar(
    'paywall_controller_nothing_to_restore_title'.tr,
    'paywall_controller_nothing_to_restore_message'.tr,
  );

  void _alreadyOwned() => showAppSnackbar(
    'paywall_controller_already_owned_title'.tr,
    'paywall_controller_already_owned_message'.tr,
  );
}
