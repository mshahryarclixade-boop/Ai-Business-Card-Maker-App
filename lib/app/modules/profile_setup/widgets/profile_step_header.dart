import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProfileStepHeader extends StatelessWidget {
  const ProfileStepHeader({super.key, required this.step, this.totalSteps = 2});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < totalSteps; i++) ...[
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: i < step
                        ? AppColors.profileStepActive
                        : AppColors.profileStepInactive,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              if (i != totalSteps - 1) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Step $step of $totalSteps',
          style: const TextStyle(
            fontFamily: 'Onest',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0,
            color: AppColors.profileStepLabel,
          ),
        ),
      ],
    );
  }
}