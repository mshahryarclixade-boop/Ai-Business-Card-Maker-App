import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProfileHintCard extends StatelessWidget {
  const ProfileHintCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.profileHintBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.profileHintBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/profile_detail_icon.png',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.2,
                letterSpacing: 0,
                color: AppColors.profileHintText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}