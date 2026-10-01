import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NoResultsState extends StatelessWidget {
  final String query;

  const NoResultsState({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                'Results',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.contactsSubtitleGrey,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'No matching contacts',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: AppColors.contactsSubtitleGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
