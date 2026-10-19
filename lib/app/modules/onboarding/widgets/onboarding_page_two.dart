import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'onboarding_constrained.dart';
import 'onboarding_feature_tile.dart';
import '../../../core/translations/tr_extension.dart';

class OnboardingPageTwo extends StatelessWidget {
  const OnboardingPageTwo({super.key});

  static const _headingStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: AppColors.splashTextPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: OnboardingConstrained(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  style: _headingStyle,
                  children: [
                    TextSpan(text: 'onboarding_page2_heading_line1'.tr),
                    TextSpan(
                      text: 'onboarding_page2_heading_line2'.tr,
                      style: _headingStyle.copyWith(
                        color: AppColors.onboardingAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'onboarding_page2_subtitle'.tr,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 26 / 20,
                  letterSpacing: 0,
                  color: AppColors.splashTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              for (int i = 0; i < onboardingFeatures.length; i++) ...[
                OnboardingFeatureTile(
                  feature: onboardingFeatures[i],
                  boxed: true,
                ),
                if (i != onboardingFeatures.length - 1)
                  const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}