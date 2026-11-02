import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/translations/tr_extension.dart';

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
          'profile_setup_step_of'.trParams({'step': step, 'total': totalSteps}),
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

/// Route argument set by Home's "Generate First Card" button.
const profileSetupFromHome = {'fromHome': true};

/// True when the profile input screens were opened from Home (not straight
/// from onboarding).
bool get openedFromHome =>
    Get.arguments is Map && (Get.arguments as Map)['fromHome'] == true;

/// The top back button of the profile input screens. Only there when the
/// user came from Home; after onboarding there is nothing to go back to.
class ProfileBackButton extends StatelessWidget {
  const ProfileBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!openedFromHome) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IconButton(
        padding: EdgeInsets.zero,
        alignment: AlignmentDirectional.centerStart,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        onPressed: () => Get.back(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.splashTextPrimary,
        ),
      ),
    );
  }
}
