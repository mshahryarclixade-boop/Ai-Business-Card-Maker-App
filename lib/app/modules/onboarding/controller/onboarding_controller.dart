import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../routes/app_routes.dart';

class OnboardingController extends GetxController {
  /// GetStorage key: true once the user has finished or skipped onboarding.
  static const String seenKey = 'onboarding_seen';

  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final int totalPages = 3;

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
      _finish();
    }
  }

  void skip() => _finish();

  /// Remembers that onboarding was seen, so it is never shown again.
  void _finish() {
    GetStorage().write(seenKey, true);
    Get.offAllNamed(Routes.MAIN);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}