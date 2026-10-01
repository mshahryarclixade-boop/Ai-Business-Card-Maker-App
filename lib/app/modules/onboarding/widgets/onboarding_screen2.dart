import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'onboarding_faded_image.dart';
import 'onboarding_bottom_shadow.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top prompt card
        Container(
          width: double.infinity,
          height: 95,
          constraints: const BoxConstraints(maxWidth: 361),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4FD),
            borderRadius: BorderRadius.circular(10.46),
            border: Border.all(color: const Color(0xFFFFFFFF), width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                offset: Offset(0, 4.78),
                blurRadius: 37.2,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                width: 33,
                height: 32,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(Icons.auto_awesome, color: Color(0xFF6D64D9)),
                ),
              ),
              const SizedBox(width: 20),
              const SizedBox(
                width: 170,
                child: Text(
                  'Minimal dark card for\na photographer...',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    color: Color(0xFFA0A0B1),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 58,
                height: 53,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF6D64D9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFFFFFFFF),
                  size: 19,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            OnboardingFadedImage(
              asset: 'assets/images/onboarding2.png',
              width: 320,
              fadeStart: 1,
              shadowWidthFactor: 0, // internal glow off, using exact shape below
            ),
            const OnboardingBottomShadow(gap: 20),
          ],
        ),

        const SizedBox(height: 93),

        const Text(
          'Describe it and AI builds it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.titleDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Professional cards in under 30 seconds\nno designer needed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.textSubtitle,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              'Used by many professionals',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}