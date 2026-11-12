import '../services/paywall_triggers.dart';
import 'package:get/get.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../routes/app_routes.dart';
import '../controller/subscription_controller.dart';
import 'paywall_view_2.dart';

/// Route arguments for the paywall.
class PaywallArgs {
  const PaywallArgs({
    required this.source,
    this.isLaunch = false,
    this.headline,
    this.headlineBuilder,
    this.skippable = false,
  });

  /// Analytics source (where the paywall was opened from).
  final String source;

  /// True when shown at app launch — closing/subscribing continues to Home
  /// instead of popping back.
  final bool isLaunch;

  /// Replaces the paywall's headline (e.g. "Scan unlimited cards").
  final String? headline;

  /// The headline computed when it is shown, so it follows a language change
  /// while the paywall is open (the phone's language or the app's).
  final String? Function()? headlineBuilder;

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
const _careerSources = {
  'career_builder',
  'career_optimizer',
  'career_fix_all',
  'career_fix_locked',
  'career_rewrite',
};

Future<bool> openPaywall({
  required String source,
  bool plans = false,
  String? headline,
  String? Function()? headlineBuilder,
  bool skippable = false,

  /// The screen the user was on (analytics `screen`; `source` is the trigger).
  String? screen,
}) async {
  // Paywalls opened from Career Studio carry its own headline.
  if (headline == null && headlineBuilder == null && _careerSources.contains(source)) {
    headlineBuilder = () =>
        RemoteConfigService().paywallConfig.headlineFor('career') ??
        croText('career_headline');
  }
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
    headlineBuilder: headlineBuilder,
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
  }
  AnalyticsService.endPaywall();
  return pro;
}
