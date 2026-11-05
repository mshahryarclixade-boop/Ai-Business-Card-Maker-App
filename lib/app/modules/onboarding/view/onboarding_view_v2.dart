import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/onboarding_controller.dart';
import '../widgets/onboarding_bottom_actions.dart';
import '../widgets/onboarding_constrained.dart';
import '../widgets/onboarding_page_one.dart';

/// Onboarding is a single screen: no pages, no swiping, no scrolling.
class OnboardingViewV2 extends GetView<OnboardingController> {
  const OnboardingViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: OnboardingFit(child: OnboardingPageOne())),
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
