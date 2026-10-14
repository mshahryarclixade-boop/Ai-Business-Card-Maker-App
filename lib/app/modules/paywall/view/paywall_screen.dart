import 'package:get/get.dart';

import '../../../core/services/analytics_service.dart';
import '../../../routes/app_routes.dart';
import 'paywall_view_2.dart';

/// Route arguments for the paywall.
class PaywallArgs {
  const PaywallArgs({required this.source, this.isLaunch = false});

  /// Analytics source (where the paywall was opened from).
  final String source;

  /// True when shown at app launch — closing/subscribing continues to Home
  /// instead of popping back.
  final bool isLaunch;
}

/// Opens the paywall and completes when it closes (subscribed or not).
/// [plans]: straight to the screen with both plans (PaywallView2) instead
/// of the yearly trial pitch first — for the crown buttons and Settings.
Future<void> openPaywall({required String source, bool plans = false}) async {
  AnalyticsService.logPaywallShown(source);
  final args = PaywallArgs(source: source);
  if (plans) {
    await Get.to(
      () => const PaywallView2(pops: 1),
      arguments: args,
      transition: Transition.rightToLeft,
    );
  } else {
    await Get.toNamed(Routes.PAYWALL, arguments: args);
  }
}
