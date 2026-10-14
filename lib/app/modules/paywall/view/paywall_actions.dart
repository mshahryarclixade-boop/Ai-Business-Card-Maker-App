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

  static Future<void> buy(
    BuildContext context, {
    required String productId,
    required String plan,
    int pops = 1,
  }) async {
    final unlocked = await Get.find<SubscriptionController>().buy(
      context,
      productId: productId,
      plan: plan,
      source: _args.source,
    );
    if (unlocked) exit(pops: pops);
  }

  static Future<void> restore(BuildContext context, {int pops = 1}) async {
    final restored = await Get.find<SubscriptionController>().restorePurchase(
      context,
      source: _args.source,
    );
    if (restored) exit(pops: pops);
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
