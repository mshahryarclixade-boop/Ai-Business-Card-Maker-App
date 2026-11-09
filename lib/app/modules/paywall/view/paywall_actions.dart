import '../../../core/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controller/subscription_controller.dart';
import '../services/offer_service.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/offer_sheet.dart';
import 'paywall_screen.dart';

/// Shared purchase / restore / close behaviour for both paywall screens.
abstract final class PaywallActions {
  static PaywallArgs get _args {
    final a = Get.arguments;
    return a is PaywallArgs ? a : const PaywallArgs(source: 'unknown');
  }

  /// A headline the trigger asked for (e.g. "Scan unlimited cards"), if any.
  static String? get headline => _args.headline;

  /// The close button must be visible at once (warning and onboarding
  /// paywalls), whatever `show_close_button` says.
  static bool get skippable => _args.skippable;

  /// The X: leaves the paywall; the first time it is left without buying, the
  /// one-time first-year offer shows over it first (once ever, when a
  /// discounted store product is set up - see OfferService).
  static Future<void> close(BuildContext context, {int pops = 1}) async {
    final offers = Get.isRegistered<OfferService>() ? OfferService.to : null;
    if (offers != null && offers.canShowFirstYear()) {
      final bought = await showOfferSheet(
        context,
        OfferType.firstYear,
        source: _args.source,
      );
      if (bought) {
        exit(pops: pops); // now Pro: the paywall is done
        return;
      }
    }
    exit(pops: pops);
  }

  /// Leaves the paywall: at launch it continues to Home; when opened from
  /// inside the app it pops back [pops] screens.
  static void exit({int pops = 1}) {
    if (_args.isLaunch) {
      AnalyticsService.endPaywall();
      Get.offAllNamed(Routes.MAIN);
    } else {
      Get.closeAllSnackbars();
      for (var i = 0; i < pops; i++) {
        Get.back();
      }
    }
  }

  /// True while a purchase or restore runs: the buttons show a spinner and
  /// repeat taps are ignored — a second purchase started meanwhile fails
  /// with "already in progress" over the open store sheet.
  static final busy = false.obs;

  static Future<void> buy(
    BuildContext context, {
    required String productId,
    required String plan,
    int pops = 1,
  }) async {
    if (busy.value) return;
    busy.value = true;
    try {
      final unlocked = await Get.find<SubscriptionController>().buy(
        context,
        productId: productId,
        plan: plan,
        source: _args.source,
      );
      if (unlocked) exit(pops: pops);
    } finally {
      busy.value = false;
    }
  }

  static Future<void> restore(BuildContext context, {int pops = 1}) async {
    if (busy.value) return;
    busy.value = true;
    try {
      final restored = await Get.find<SubscriptionController>().restorePurchase(
        context,
        source: _args.source,
      );
      if (restored) exit(pops: pops);
    } finally {
      busy.value = false;
    }
  }

  static Future<void> buyMonthly(BuildContext context, {int pops = 1}) => buy(
    context,
    productId: RevenueCatHelper.monthlyProductId,
    plan: 'monthly',
    pops: pops,
  );

  static Future<void> buyYearly(BuildContext context, {int pops = 1}) => buy(
    context,
    productId: RevenueCatHelper.yearlyProductId,
    plan: 'yearly',
    pops: pops,
  );
}

/// A paywall buy button's label, swapped for a spinner while
/// [PaywallActions.busy].
class PaywallBusy extends StatelessWidget {
  const PaywallBusy({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Obx(
    () => PaywallActions.busy.value
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
        : child,
  );
}
