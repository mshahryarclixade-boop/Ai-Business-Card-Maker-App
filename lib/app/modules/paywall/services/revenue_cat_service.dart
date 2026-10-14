import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/credits_controller.dart';
import 'subscription_credit_policy.dart';
import 'user_credits_manager.dart';

abstract class InAppCallback {
  void onPurchaseSuccess(BuildContext context);

  /// [code] lets the caller show a specific message (pending approval,
  /// already owned, offline) instead of one generic failure.
  void onPurchaseFailure(BuildContext context, PurchasesErrorCode code);

  void onPurchasedRestored(BuildContext context);

  void onPurchaseExpired(BuildContext context);

  void onPurchaseCancelled(BuildContext context);

  void onPurchaseRestoreFailed(BuildContext context);
}

/// Ported from face_swap's `RevenueCatHelper` — same shape (configure,
/// buy, check status, restore, assign local credits from the real
/// entitlement), adapted to this app's own products/entitlement. Fill in
/// the keys once the RevenueCat project exists; until then init is skipped
/// and every call below returns the free-tier answer.
class RevenueCatHelper {
  static const String entitlementIdentifier =
      'business card entitlement premium';

  // RevenueCat dashboard → Project settings → API keys (public SDK keys —
  // safe to ship in the app).
  static const String _androidApiKey = 'goog_xiEfHIkDYUzClzHSZbXSvDvpRGe';
  static const String _iosApiKey = 'appl_dKKGxMhhuRCulFBVJsUjqZQulYA';

  // Google Play product ids.
  static const _androidWeeklyProductId = 'aivoice_weekly';
  static const _androidMonthlyProductId = 'business_card_monthly';
  static const _androidYearlyProductId = 'business_card_yearly';

  // App Store product ids.
  static const _iosWeeklyProductId = 'aivoice_weekly';
  static const _iosMonthlyProductId = 'business_card_monthly';
  static const _iosYearlyProductId = 'business_card_yearly';

  static String get weeklyProductId =>
      Platform.isIOS ? _iosWeeklyProductId : _androidWeeklyProductId;
  static String get monthlyProductId =>
      Platform.isIOS ? _iosMonthlyProductId : _androidMonthlyProductId;
  static String get yearlyProductId =>
      Platform.isIOS ? _iosYearlyProductId : _androidYearlyProductId;

  /// [storeId] without a Google Play base plan: RevenueCat names Play
  /// subscriptions `subscriptionId:basePlanId` (`aivoice_weekly:weekly`),
  /// App Store ones just the product id. Compare product ids through this.
  static String productIdOf(String storeId) => storeId.split(':').first;

  static List<String> get productIdentifiers => [
    yearlyProductId,
    monthlyProductId,
    weeklyProductId,
  ];

  static const String lastExpirationKey = 'last_expiration_date';

  static bool _configured = false;
  static bool get isConfigured => _configured;

  /// RevenueCat's id for this user (sent to the chat function so it can
  /// verify Pro server-side); null when the SDK isn't configured.
  static Future<String?> appUserId() async {
    if (!_configured) return null;
    try {
      return await Purchases.appUserID;
    } catch (_) {
      return null;
    }
  }

  /// No-op off Android/iOS/macOS (purchases_flutter's native plugin only
  /// ships for those) and while the API key is still empty. Any other
  /// failure is swallowed rather than crashing app startup.
  Future<void> initPlatformState() async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) return;
    final apiKey = Platform.isAndroid ? _androidApiKey : _iosApiKey;
    if (apiKey.isEmpty) {
      log('RevenueCat API key not set — skipping', name: 'RevenueCatHelper');
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;
      await setupPurchaseListener();
      log(
        'configured — entitlement="$entitlementIdentifier", '
        'productIds: ${productIdentifiers.join(", ")}',
        name: 'RevenueCatHelper',
      );
    } catch (e) {
      log('RevenueCat init failed: $e', name: 'RevenueCatHelper');
    }
  }

  Future<void> setupPurchaseListener() async {
    Purchases.addCustomerInfoUpdateListener((customerInfo) async {
      await _handleSubscriptionChange(customerInfo);
    });
  }

  /// Calls [onChange] with the entitlement's active state on every
  /// CustomerInfo update (purchase, renewal, expiry).
  void addListener(void Function(bool isPro) onChange) {
    if (!_configured) return;
    Purchases.addCustomerInfoUpdateListener(
      (info) => onChange(_isActive(info)),
    );
  }

  Future<void> buyProduct(
    StoreProduct product,
    InAppCallback callback,
    BuildContext context,
  ) async {
    try {
      final params = PurchaseParams.storeProduct(product);
      final purchaseResult = await Purchases.purchase(params);
      final customerInfo = purchaseResult.customerInfo;
      final entitlement = customerInfo.entitlements.all[entitlementIdentifier];
      if (entitlement != null && entitlement.isActive) {
        await _checkAndAssignCredits(
          entitlement.productIdentifier,
          entitlement.latestPurchaseDate,
          entitlement.periodType,
        );
        log(
          '✅ Purchase succeeded — product=${product.identifier}',
          name: 'RevenueCatHelper',
        );
        if (context.mounted) callback.onPurchaseSuccess(context);
      } else {
        // Paid, but the entitlement isn't attached to this product in the
        // dashboard — Pro can't unlock, so report it rather than hang.
        log(
          '❌ Purchase went through but "$entitlementIdentifier" is not '
          'active — product=${product.identifier}',
          name: 'RevenueCatHelper',
        );
        if (context.mounted) {
          callback.onPurchaseFailure(context, PurchasesErrorCode.unknownError);
        }
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        log(
          'Purchase cancelled by user — product=${product.identifier}',
          name: 'RevenueCatHelper',
        );
      } else {
        log(
          '❌ Purchase failed — product=${product.identifier}, '
          'code=${errorCode.name}: ${e.message}',
          name: 'RevenueCatHelper',
        );
      }
      if (context.mounted) {
        if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
          callback.onPurchaseCancelled(context);
        } else {
          callback.onPurchaseFailure(context, errorCode);
        }
      }
    } catch (e) {
      log(
        '❌ Purchase failed (non-platform) — product=${product.identifier}: $e',
        name: 'RevenueCatHelper',
      );
      if (context.mounted) {
        callback.onPurchaseFailure(context, PurchasesErrorCode.unknownError);
      }
    }
  }

  /// Whether the entitlement is active — null when that can't be known
  /// (not configured, or the store call failed), so a paying user isn't
  /// downgraded over a network error.
  Future<bool?> checkSubscriptionStatus() async {
    if (!_configured) return null;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _logCustomerInfo(customerInfo, header: 'checkSubscriptionStatus');

      final entitlement = customerInfo.entitlements.all[entitlementIdentifier];
      if (entitlement == null || !entitlement.isActive) {
        log(
          '❌ No active "$entitlementIdentifier" entitlement — free tier',
          name: 'RevenueCatHelper',
        );
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      if (entitlement.expirationDate != null) {
        await prefs.setString(
          lastExpirationKey,
          DateTime.parse(entitlement.expirationDate!).toIso8601String(),
        );
      }
      await _checkAndAssignCredits(
        entitlement.productIdentifier,
        entitlement.latestPurchaseDate,
        entitlement.periodType,
      );
      return true;
    } catch (e) {
      log('checkSubscriptionStatus error: $e', name: 'RevenueCatHelper');
      return null;
    }
  }

  /// Dumps every entitlement/active-subscription on [customerInfo] — same
  /// structured-log style for every read of a fresh `CustomerInfo`
  /// (status checks, the update listener), so a support conversation can be
  /// debugged straight from device logs.
  void _logCustomerInfo(CustomerInfo customerInfo, {required String header}) {
    log('══════════ $header ══════════', name: 'RevenueCatHelper');
    log(
      'originalAppUserId=${customerInfo.originalAppUserId}, '
      'firstSeen=${customerInfo.firstSeen}, '
      'requestDate=${customerInfo.requestDate}, '
      'latestExpiration=${customerInfo.latestExpirationDate}',
      name: 'RevenueCatHelper',
    );
    if (customerInfo.activeSubscriptions.isEmpty) {
      log('activeSubscriptions: none', name: 'RevenueCatHelper');
    } else {
      log(
        'activeSubscriptions: ${customerInfo.activeSubscriptions.join(", ")}',
        name: 'RevenueCatHelper',
      );
    }
    for (final entitlement in customerInfo.entitlements.all.values) {
      final prefix = entitlement.isActive ? '✅' : '  ';
      log(
        '$prefix entitlement="${entitlement.identifier}" '
        'active=${entitlement.isActive} '
        'product=${entitlement.productIdentifier} '
        'period=${entitlement.periodType.name} '
        'expiration=${entitlement.expirationDate}',
        name: 'RevenueCatHelper',
      );
    }
    log('══════════════════════════════════════', name: 'RevenueCatHelper');
  }

  Future<List<Package>> fetchAvailablePackages() async {
    if (!_configured) return [];
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        log('Error fetching offerings: $e', name: 'RevenueCatHelper');
      }
      return [];
    }
  }

  Future<List<StoreProduct>> getProducts() async {
    if (!_configured) return [];
    try {
      final products = await Purchases.getProducts(productIdentifiers);
      if (products.isEmpty) {
        log(
          'no products fetched (ids: ${productIdentifiers.join(", ")})',
          name: 'RevenueCatHelper',
        );
      }
      for (final p in products) {
        log(
          'product: ${p.identifier} → ${p.priceString}',
          name: 'RevenueCatHelper',
        );
      }
      final found = products.map((p) => productIdOf(p.identifier)).toSet();
      final missing = productIdentifiers
          .where((id) => !found.contains(id))
          .toList();
      if (missing.isNotEmpty) {
        log('invalidProductIdentifiers: $missing', name: 'RevenueCatHelper');
      }
      return products;
    } catch (e) {
      log('getProducts error: $e', name: 'RevenueCatHelper');
      return [];
    }
  }

  Future<void> restorePurchases(
    BuildContext context,
    InAppCallback callback,
  ) async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _logCustomerInfo(customerInfo, header: 'restorePurchases');

      final entitlement = customerInfo.entitlements.all[entitlementIdentifier];
      final isActive = entitlement?.isActive ?? false;
      log(
        isActive
            ? '✅ Restore found active entitlement — product=${entitlement!.productIdentifier}'
            : 'Restore found no active "$entitlementIdentifier" entitlement',
        name: 'RevenueCatHelper',
      );
      if (!context.mounted) return;
      if (isActive) {
        callback.onPurchasedRestored(context);
      } else {
        callback.onPurchaseExpired(context);
      }
    } on PlatformException catch (e) {
      log('Restore failed: ${e.message}', name: 'RevenueCatHelper');
      if (context.mounted) callback.onPurchaseRestoreFailed(context);
    } catch (e) {
      log('Unexpected restore error: $e', name: 'RevenueCatHelper');
      if (context.mounted) callback.onPurchaseRestoreFailed(context);
    }
  }

  Future<String?> getActivePlan() async {
    if (!_configured) return null;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[entitlementIdentifier];
      if (entitlement != null && entitlement.isActive) {
        return entitlement.productIdentifier;
      }
      return null;
    } catch (e) {
      log('getActivePlan error: $e', name: 'RevenueCatHelper');
      return null;
    }
  }

  bool _isActive(CustomerInfo info) =>
      info.entitlements.all[entitlementIdentifier]?.isActive ?? false;

  Future<void> _handleSubscriptionChange(CustomerInfo customerInfo) async {
    _logCustomerInfo(customerInfo, header: 'CustomerInfo update');
    final entitlement = customerInfo.entitlements.all[entitlementIdentifier];
    if (entitlement == null || !entitlement.isActive) {
      log('Subscription inactive or expired', name: 'RevenueCatHelper');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await _checkAndAssignCredits(
      entitlement.productIdentifier,
      entitlement.latestPurchaseDate,
      entitlement.periodType,
    );
    await prefs.setBool(UserCreditsManager.proStatusKey, true);
    if (entitlement.expirationDate != null) {
      await prefs.setString(
        lastExpirationKey,
        DateTime.parse(entitlement.expirationDate!).toIso8601String(),
      );
    }
  }

  /// Assigns credits when needed — handles both genuine renewals and a
  /// genuinely new device. Uses [latestPurchaseDate] (billing period start)
  /// as the anchor, compared against the last-assigned date
  /// [UserCreditsManager] mirrors to/from Firestore (not raw
  /// SharedPreferences) — so a reinstall correctly restores the real
  /// last-assigned date along with the balance it applies to, instead of
  /// looking like "never assigned" and re-granting a full pool on top of an
  /// already-correct balance.
  Future<void> _checkAndAssignCredits(
    String productId,
    String? latestPurchaseDate,
    PeriodType periodType,
  ) async {
    final creditsManager = UserCreditsManager();
    final shouldAssign = shouldReassignCredits(
      lastAssignedIso: await creditsManager.getLastCreditAssignedDate(),
      latestPurchaseDateIso: latestPurchaseDate,
      storedPlanTier: await creditsManager.getPlanTier(),
      newPlanTier: planTierForProduct(productId, periodType),
    );
    if (!shouldAssign) return;

    await _assignCreditsOnRenewal(productId, periodType);
    if (latestPurchaseDate != null) {
      await creditsManager.setLastCreditAssignedDate(
        DateTime.parse(latestPurchaseDate).toIso8601String(),
      );
    }
  }

  Future<void> _assignCreditsOnRenewal(
    String productId,
    PeriodType periodType,
  ) async {
    final planTier = planTierForProduct(productId, periodType);
    if (planTier == null) {
      log(
        'Unknown productId "$productId" — no credits assigned',
        name: 'RevenueCatHelper',
      );
      return;
    }

    await UserCreditsManager().setPro(true, planTier);
    CreditsController.bump();
    log(
      '✅ Pro activated — product=$productId, period=${periodType.name}, '
      'planTier=$planTier',
      name: 'RevenueCatHelper',
    );
  }
}
