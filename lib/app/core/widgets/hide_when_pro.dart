import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../modules/paywall/controller/subscription_controller.dart';

/// Shows [child] (a crown, a "Pro" badge, an upgrade banner) only while the
/// user is NOT subscribed. It follows the live subscription, so it disappears
/// as soon as a purchase or a restore succeeds, and stays for free users.
class HideWhenPro extends StatelessWidget {
  const HideWhenPro({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SubscriptionController>()) return child;
    final sub = Get.find<SubscriptionController>();
    return Obx(() => sub.isUserPro.value ? const SizedBox.shrink() : child);
  }
}
