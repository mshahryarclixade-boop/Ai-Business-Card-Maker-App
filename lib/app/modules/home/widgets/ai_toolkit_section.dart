import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../career_studio/view/career_studio_view.dart';
import '../../career_studio/view/profile_builder_view.dart';
import '../../career_studio/view/profile_optimizer_view.dart';

/// "Your AI toolkit" on Home: Career Studio and AI Business Analyst.
/// UI and navigation only.
class AiToolkitSection extends StatelessWidget {
  const AiToolkitSection({super.key});

  void _open(Widget page) =>
      Get.to(() => page, transition: Transition.rightToLeft);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Your AI toolkit',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.crownGold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ToolkitCard(
          onTap: () => _open(const CareerStudioView()),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Center(
                child: Image.asset(
                  'assets/images/toolkit/career.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          title: 'Career Studio',
          subtitle: 'Build or optimize your LinkedIn profile',
          footer: Row(
            children: [
              _ToolkitButton(
                label: 'Build profile',
                filled: true,
                onTap: () => _open(const ProfileBuilderView()),
              ),
              const SizedBox(width: 8),
              _ToolkitButton(
                label: 'Optimize profile',
                filled: false,
                onTap: () => _open(const ProfileOptimizerView()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _ToolkitCard(
          leading: _AvatarPair(),
          title: 'AI Business Analyst',
          subtitle: 'Talk to AI investors about your idea',
          trailing: _FreeBadge('3 free'),
        ),
      ],
    );
  }
}

class _ToolkitCard extends StatelessWidget {
  const _ToolkitCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.footer,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? footer;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pillBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titleDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11.5,
                        height: 1.3,
                        color: AppColors.textBody,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 10),
                      footer!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolkitButton extends StatelessWidget {
  const _ToolkitButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.onboardingBtnEnd : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : AppColors.onboardingBtnEnd,
          ),
        ),
      ),
    );
  }
}

class _AvatarPair extends StatelessWidget {
  const _AvatarPair();

  @override
  Widget build(BuildContext context) {
    Widget avatar(String asset) => Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(child: Image.asset(asset, fit: BoxFit.cover)),
    );

    return SizedBox(
      width: 62,
      height: 43,
      child: Stack(
        children: [
          avatar('assets/images/toolkit/person2.png'),
          Positioned(
            left: 24,
            child: avatar('assets/images/toolkit/person1.png'),
          ),
        ],
      ),
    );
  }
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    );
  }
}
