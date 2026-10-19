import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/translations/tr_extension.dart';

class OnboardingFeature {
  const OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;
}

const onboardingFeatures = [
  OnboardingFeature(
    icon: 'assets/icons/onboarding1_icon1.png',
    title: 'onboarding_feature_create_ai_title',
    description: 'onboarding_feature_description',
  ),
  OnboardingFeature(
    icon: 'assets/icons/onboarding1_icon2.png',
    title: 'onboarding_feature_templates_title',
    description: 'onboarding_feature_description',
  ),
  OnboardingFeature(
    icon: 'assets/icons/onboarding1_icon3.png',
    title: 'onboarding_feature_qr_title',
    description: 'onboarding_feature_description',
  ),
];

class OnboardingFeatureTile extends StatelessWidget {
  const OnboardingFeatureTile({
    super.key,
    required this.feature,
    this.boxed = false,
  });

  final OnboardingFeature feature;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: boxed
          ? const EdgeInsets.all(18)
          : const EdgeInsets.symmetric(vertical: 18),
      decoration: boxed
          ? BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.onboardingCardShadow,
            offset: Offset(0, 0.74),
            blurRadius: 32.53,
          ),
        ],
      )
          : null,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.onboardingIconBg,
              borderRadius: BorderRadius.circular(14.22),
            ),
            alignment: Alignment.center,
            child: Image.asset(feature.icon, width: 27, height: 27),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title.tr,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 22 / 20,
                    letterSpacing: 0,
                    color: AppColors.splashTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description.tr,
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                    height: 22 / 16,
                    letterSpacing: 0,
                    color: AppColors.splashTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}