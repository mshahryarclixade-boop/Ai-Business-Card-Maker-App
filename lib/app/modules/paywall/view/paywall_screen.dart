import 'package:get/get.dart';

import '../../../core/services/analytics_service.dart';
import '../../../routes/app_routes.dart';

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
Future<void> openPaywall({required String source}) async {
  AnalyticsService.logPaywallShown(source);
  await Get.toNamed(Routes.PAYWALL, arguments: PaywallArgs(source: source));
}
