import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  /// GetStorage key: true once the user has finished or skipped onboarding.
  static const String seenKey = 'onboarding_seen';

  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final int totalPages = 2;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> next() async {
    if (currentPage.value < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _markSeen();
      FirebaseAnalytics.instance.logEvent(name: 'onboarding_completed');
      Get.offAllNamed(Routes.PERSONAL_DETAILS);
    }
  }

  /// "I'll do it later": go straight to Home.
  Future<void> skip() async {
    await _markSeen();
    FirebaseAnalytics.instance.logEvent(
      name: 'onboarding_skipped',
      parameters: {'page': currentPage.value},
    );
    Get.offAllNamed(Routes.MAIN);
  }

  /// Remembers that onboarding was completed (finished or skipped). Only
  /// called from [next] and [skip]: merely viewing onboarding, pressing Back
  /// or closing the app leaves it incomplete, so it is shown again.
  Future<void> _markSeen() => GetStorage().write(seenKey, true);

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}