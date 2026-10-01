import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  /// Background of the small icon chip. Defaults to a light lavender
  /// tint of [AppColors.primary].
  final Color? iconBackgroundColor;

  /// Colour of the icon itself. Defaults to [AppColors.primary].
  final Color? iconColor;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconBackgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconBackgroundColor ??
                AppColors.contactsLavenderBg.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor ?? AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.contactsTitleDark,
          ),
        ),
      ],
    );
  }
}