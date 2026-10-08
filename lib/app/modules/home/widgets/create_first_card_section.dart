import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../profile_setup/service/profile_store.dart';

/// Shown on Home in place of the card preview while the user has no card
/// (for example after tapping "I'll do it later" in onboarding).
class CreateFirstCardSection extends StatelessWidget {
  const CreateFirstCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final name = ProfileStore.to.profile.value.fullName.trim();
          final first = name.isEmpty ? '' : name.split(' ').first;
          return Text(
            first.isEmpty ? 'Welcome' : 'Welcome, $first',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          );
        }),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 7 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x4444449A), width: 1.5),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your business card will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add your details and AI will design it for you',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            // toNamed (not offAllNamed) so Back returns to Home.
            onPressed: () => Get.toNamed(Routes.PERSONAL_DETAILS),
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text(
              'Create Your First Card',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}