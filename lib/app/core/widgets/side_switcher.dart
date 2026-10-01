import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../modules/custom_create/controller/card_editor_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Small "‹ Front ›" switcher shown above the top-right of the canvas.
class SideSwitcher extends StatelessWidget {
  final CardEditorController controller;

  const SideSwitcher({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isBack = controller.currentSide.value == 1;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Arrow(
            icon: Icons.chevron_left_rounded,
            enabled: isBack,
            onTap: () => controller.switchToSide(0),
          ),
          SizedBox(
            width: 40,
            child: Text(
              isBack ? 'Back' : 'Front',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.titleDark,
              ),
            ),
          ),
          _Arrow(
            icon: Icons.chevron_right_rounded,
            enabled: !isBack,
            onTap: () => controller.switchToSide(1),
          ),
        ],
      );
    });
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _Arrow({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.titleDark.withValues(alpha: enabled ? 1 : 0.3),
        ),
      ),
    );
  }
}