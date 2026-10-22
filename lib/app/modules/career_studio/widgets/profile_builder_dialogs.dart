import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';

/// "Leave the builder?" Returns true when the user chooses Leave.
Future<bool?> showLeaveBuilderDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'career_builder_leave_title'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'career_builder_leave_message'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSubtitle,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: 'career_builder_leave'.tr,
                    onTap: () => Navigator.of(ctx).pop(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: 'career_builder_keep_going'.tr,
                    filled: true,
                    onTap: () => Navigator.of(ctx).pop(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: filled ? AppColors.onboardingBtnEnd : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: filled ? null : Border.all(color: AppColors.pillBorder),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : AppColors.titleDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
