import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';

/// Paywall funnel events. Never throws — analytics must not break a purchase.
abstract final class AnalyticsService {
  static void _log(String name, Map<String, Object> params) {
    try {
      FirebaseAnalytics.instance
          .logEvent(name: name, parameters: params)
          .catchError((Object e) => log('analytics: $e', name: 'Analytics'));
    } catch (e) {
      log('analytics: $e', name: 'Analytics');
    }
  }

  static void logPaywallShown(String source) =>
      _log('paywall_shown', {'source': source});

  static void logPaywallPurchaseTapped(String plan, String source) =>
      _log('paywall_purchase_tapped', {'plan': plan, 'source': source});

  static void logPaywallPurchased(String plan, String source) =>
      _log('paywall_purchased', {'plan': plan, 'source': source});

  static void logPaywallPurchaseCancelled(String plan, String source) =>
      _log('paywall_purchase_cancelled', {'plan': plan, 'source': source});

  static void logPaywallPurchaseFailed(
    String plan,
    String reason,
    String source,
  ) => _log('paywall_purchase_failed', {
    'plan': plan,
    'reason': reason,
    'source': source,
  });

  static void logPaywallRestoreTapped(String source) =>
      _log('paywall_restore_tapped', {'source': source});

  static void logPaywallRestored({
    required bool restored,
    required String source,
  }) => _log('paywall_restored', {'restored': restored ? 1 : 0, 'source': source});

  static void logPaywallRestoreFailed(String source) =>
      _log('paywall_restore_failed', {'source': source});
}
