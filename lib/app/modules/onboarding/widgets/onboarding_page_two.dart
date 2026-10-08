import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'onboarding_feature_tile.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              style: _headingStyle,
              children: [
                const TextSpan(text: 'Your Card.\n'),
                TextSpan(
                  text: 'Endless\nPossibilities.',
                  style: _headingStyle.copyWith(
                    color: AppColors.onboardingAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'A memorable introduction, made in minutes',
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
            OnboardingFeatureTile(feature: onboardingFeatures[i], boxed: true),
            if (i != onboardingFeatures.length - 1) const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}