import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';


/// UPPER CARD FOR COMPANY INFO
class CompanyInfoCard extends StatelessWidget {
  final String companyName;
  final String jobTitle;

  const CompanyInfoCard({
    super.key,
    required this.companyName,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (companyName.isEmpty && jobTitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (companyName.isNotEmpty)
            Text(
              companyName,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.contactsTitleDark,
              ),
            ),
          if (jobTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                jobTitle,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.contactsTitleDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}