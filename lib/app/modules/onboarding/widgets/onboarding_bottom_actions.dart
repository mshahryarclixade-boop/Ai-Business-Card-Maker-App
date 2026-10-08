import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingBottomActions extends StatelessWidget {
  const OnboardingBottomActions({
    super.key,
    required this.onPrimary,
    required this.onSecondary,
  });

  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPrimary,
            child: Container(
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                gradient: AppColors.onboardingButtonGradient,
                borderRadius: BorderRadius.circular(500),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.onboardingBtnShadow,
                    offset: Offset(0, 8),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create my Profile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 22 / 18,
                      letterSpacing: 0,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: AppColors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSecondary,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Text(
                'I’ll do it later',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 26 / 20,
                  letterSpacing: 0,
                  color: AppColors.splashTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}