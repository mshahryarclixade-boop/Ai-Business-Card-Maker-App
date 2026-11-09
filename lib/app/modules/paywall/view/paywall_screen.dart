import 'package:get/get.dart';

import '../../../core/services/analytics_service.dart';
import '../../../routes/app_routes.dart';
import '../controller/subscription_controller.dart';
import '../services/offer_service.dart';
import 'paywall_view_2.dart';

/// Route arguments for the paywall.
class PaywallArgs {
  const PaywallArgs({
    required this.source,
    this.isLaunch = false,
    this.headline,
    this.skippable = false,
  });

  /// Analytics source (where the paywall was opened from).
  final String source;

  /// True when shown at app launch — closing/subscribing continues to Home
  /// instead of popping back.
  final bool isLaunch;

  /// Replaces the paywall's headline (e.g. "Scan unlimited cards").
  final String? headline;

  /// A paywall that must be easy to leave (a warning, the onboarding one): its
  /// close button is there from the first second whatever Remote Config says.
  final bool skippable;
}

/// Opens the paywall and completes when it closes, with whether the user is
/// Pro by then.
/// [plans]: straight to the screen with both plans (PaywallView2) instead
/// of the yearly trial pitch first — for the crown buttons and Settings.
/// Most callers should go through `PaywallTriggers.show` (the CRO plan's
/// triggers: source tags, headlines, Remote Config switches).
Future<bool> openPaywall({
  required String source,
  bool plans = false,
  String? headline,
  bool skippable = false,

  /// The screen the user was on (analytics `screen`; `source` is the trigger).
  String? screen,
}) async {
  AnalyticsService.beginPaywall(screen);
  AnalyticsService.logPaywallShown(source);
  if (Get.isRegistered<SubscriptionController>()) {
    final sub = Get.find<SubscriptionController>();
    // Only once the store answered: then the yearly trial is known to be
    // there (or not) for this user.
    if (sub.products.isNotEmpty) {
      AnalyticsService.logTrialEligibility(
        eligible: sub.yearlyTrialEligible.value,
        source: source,
      );
    }
  }
  final args = PaywallArgs(
    source: source,
    headline: headline,
    skippable: skippable,
  );
  if (plans) {
    await Get.to(
      () => const PaywallView2(pops: 1),
      arguments: args,
      transition: Transition.rightToLeft,
    );
  } else {
    await Get.toNamed(Routes.PAYWALL, arguments: args);
  }
  final pro =
      Get.isRegistered<SubscriptionController>() &&
      Get.find<SubscriptionController>().isPro;
  // Closed without buying (the X, or Back).
  if (!pro) {
    AnalyticsService.logPaywallDismissed(source);
    if (Get.isRegistered<OfferService>()) OfferService.to.onPaywallDismissed();
  }
  AnalyticsService.endPaywall();
  return pro;
}
