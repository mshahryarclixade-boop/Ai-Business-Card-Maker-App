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

  void next() {
    if (currentPage.value < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _markSeen();
      Get.offAllNamed(Routes.PERSONAL_DETAILS);
    }
  }

  /// "I'll do it later": go straight to Home.
  void skip() {
    _markSeen();
    Get.offAllNamed(Routes.MAIN);
  }

  @override
  void onReady() {
    super.onReady();
    // Shown once: mark as seen as soon as the user sees it.
    _markSeen();
  }

  /// Remembers that onboarding was seen, so it is never shown again.
  void _markSeen() => GetStorage().write(seenKey, true);

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}