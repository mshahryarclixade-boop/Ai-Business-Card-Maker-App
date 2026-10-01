import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CustomLinkChip extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const CustomLinkChip({
    super.key,
    required this.url,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.contactsLavenderBg.withOpacity(0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.link,
            size: 16,
            color: AppColors.contactsSubtitleGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.contactsTitleDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.contactsSubtitleGrey,
            ),
          ),
        ],
      ),
    );
  }
}