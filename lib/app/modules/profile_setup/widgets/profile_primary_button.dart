import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProfilePrimaryButton extends StatelessWidget {
  const ProfilePrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 22 / 18,
                letterSpacing: 0,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}