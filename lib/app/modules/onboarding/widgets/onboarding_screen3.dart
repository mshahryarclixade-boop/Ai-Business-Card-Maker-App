import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'onboarding_faded_image.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        OnboardingFadedImage(
          asset: 'assets/images/onboarding3.png',
          width: 340, // ⬅️ was 290, trimmed a touch to match the others
          fadeStart: 0.85,
          shadowWidthFactor: 0,
        ),
        const SizedBox(height: 1), // ⬅️ was 6, matched to screen1/2 rhythm
        const Text(
          'Scan any card. Save\nevery contact.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.titleDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Edit text, colors, fonts, icons, and more\nto match your brand perfectly.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.textSubtitle,
          ),
        ),
      ],
    );
  }
}