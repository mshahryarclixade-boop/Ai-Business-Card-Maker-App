import 'package:get/get.dart';

import '../services/user_credits_manager.dart';

/// Reactive credit balance for the UI. Call [bump] after anything that
/// changes the stored balance (spend, refill, downgrade).
class CreditsController extends GetxController {
  /// Null until first read; -1 means unlimited.
  final balance = Rxn<int>();

  static void bump() {
    if (Get.isRegistered<CreditsController>()) {
      Get.find<CreditsController>().reload();
    }
  }

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    try {
      balance.value = await UserCreditsManager().knownBalance();
    } catch (_) {}
  }
}
