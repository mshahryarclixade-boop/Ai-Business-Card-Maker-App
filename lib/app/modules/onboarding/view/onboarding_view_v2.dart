import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/onboarding_controller.dart';
import '../widgets/onboarding_bottom_actions.dart';
import '../widgets/onboarding_page_one.dart';
import '../widgets/onboarding_page_two.dart';

class OnboardingViewV2 extends GetView<OnboardingController> {
  const OnboardingViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OnboardingController());

    const pages = [
      OnboardingPageOne(),
      OnboardingPageTwo(),
    ];

    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) => pages[index],
              ),
            ),
            OnboardingBottomActions(
              onPrimary: controller.next,
              onSecondary: controller.skip,
            ),
          ],
        ),
      ),
    );
  }
}