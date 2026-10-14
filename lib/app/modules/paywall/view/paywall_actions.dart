import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controller/subscription_controller.dart';
import '../services/revenue_cat_service.dart';
import 'paywall_screen.dart';

/// Shared purchase / restore / close behaviour for both paywall screens.
abstract final class PaywallActions {
  static PaywallArgs get _args {
    final a = Get.arguments;
    return a is PaywallArgs ? a : const PaywallArgs(source: 'unknown');
  }

  /// Leaves the paywall: at launch it continues to Home; when opened from
  /// inside the app it pops back [pops] screens.
  static void exit({int pops = 1}) {
    if (_args.isLaunch) {
      Get.offAllNamed(Routes.MAIN);
    } else {
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
