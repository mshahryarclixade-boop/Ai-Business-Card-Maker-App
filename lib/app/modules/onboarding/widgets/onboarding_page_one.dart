import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'onboarding_feature_tile.dart';

class OnboardingPageOne extends StatelessWidget {
  const OnboardingPageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            height: 182,
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.onboardingTopCardBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -7,
                  left: 22,
                  width: 308,
                  height: 196,
                  child: Image.asset(
                    'assets/images/onboarding1_image.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Card. Endless\nPossibilities.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 35,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 0,
              color: AppColors.splashTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < onboardingFeatures.length; i++) ...[
            OnboardingFeatureTile(feature: onboardingFeatures[i]),
            if (i != onboardingFeatures.length - 1) const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }
}