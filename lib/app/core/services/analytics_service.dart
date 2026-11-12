import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

import '../../modules/paywall/controller/subscription_controller.dart';

/// Paywall funnel events. Never throws — analytics must not break a purchase.
abstract final class AnalyticsService {
  /// 'pro' or 'free' (every event carries it, so funnels can be split).
  static String get subscriptionStatus {
    try {
      return Get.isRegistered<SubscriptionController>() &&
              Get.find<SubscriptionController>().isPro
          ? 'pro'
          : 'free';
    } catch (_) {
      return 'free';
    }
  }

  /// Receives every event (name, params) before it is sent; tests use it.
  static void Function(String name, Map<String, Object> params)? sink;

  /// The screen the open paywall / Pro sheet was launched from. Every paywall
  /// event (shown, dismissed, plan_selected, purchase_*, restore_*)
  /// carries it as `screen`, next to `source` (the trigger).
  static String? _paywallScreen;
  static void beginPaywall(String? screen) => _paywallScreen = screen ?? 'unknown';
  static void endPaywall() => _paywallScreen = null;

  static void _log(String name, Map<String, Object> params) {
    final screen = _paywallScreen;
    final full = {
      ...params,
      if (screen != null && params.containsKey('source')) 'screen': screen,
      'subscription_status': subscriptionStatus,
    };
    sink?.call(name, full);
    try {
      FirebaseAnalytics.instance
          .logEvent(name: name, parameters: full)
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
  }) => _log('paywall_restored', {
    'restored': restored ? 1 : 0,
    'source': source,
  });

  static void logPaywallRestoreFailed(String source) =>
      _log('paywall_restore_failed', {'source': source});

  // ---- Paywall: where it showed and how it ended ----------------------------

  /// The paywall was closed without buying (the X, or Back).
  static void logPaywallDismissed(String source) =>
      _log('paywall_dismissed', {'source': source});

  /// A plan was picked (tapped Buy on it): plan + whether its free trial was
  /// offered on screen.
  static void logPlanSelected({
    required String plan,
    required String source,
    required bool trialOffered,
  }) => _log('plan_selected', {
    'plan': plan,
    'source': source,
    'trial_offered': trialOffered ? 1 : 0,
  });

  /// The store said whether the yearly product has a free trial the user can
  /// have; the paywall shows a trial only when it is true.
  static void logTrialEligibility({
    required bool eligible,
    required String source,
  }) => _log('trial_eligibility', {
    'plan': 'yearly',
    'eligible': eligible ? 1 : 0,
    'source': source,
  });

  // ---- Free limits ----------------------------------------------------------

  /// One free use was spent. [used]/[limit] are after this use.
  static void logUsageConsumed({
    required String feature,
    required int used,
    required int limit,
    String? source,
  }) => _log('usage_consumed', {
    'feature': feature,
    'used': used,
    'limit': limit,
    'source': ?source,
  });

  /// The user reached the limit of [feature] (the last free use was spent, or
  /// a use was refused).
  static void logLimitReached({
    required String feature,
    required int limit,
    required String source,
  }) => _log('limit_reached', {
    'feature': feature,
    'limit': limit,
    'source': source,
  });

  // ---- Experiment ------------------------------------------------

  static void logExperimentAssigned({
    required String experiment,
    required String variant,
  }) => _log('experiment_assigned', {
    'experiment': experiment,
    'variant': variant,
  });
}
