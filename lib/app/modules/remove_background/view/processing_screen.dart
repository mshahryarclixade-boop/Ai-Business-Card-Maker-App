import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.titleDark,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/images/bg_vector.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Processing Your Image...',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'This will take a few seconds',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.textSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}