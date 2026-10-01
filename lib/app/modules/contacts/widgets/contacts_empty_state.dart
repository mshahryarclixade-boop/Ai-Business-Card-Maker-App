import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'pill_button.dart';

class ContactsEmptyState extends StatelessWidget {
  final VoidCallback onAddManually;
  final VoidCallback onScanCard;

  const ContactsEmptyState({
    super.key,
    required this.onAddManually,
    required this.onScanCard,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/people.png',
              width: 55,
              height: 55,
            ),
            const SizedBox(height: 10),
            const Text(
              'No Contacts Yet',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.contactsTitleDark,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Scan a business card or add manually',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.contactsTitleDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PillButton(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan Card',
                  onTap: onScanCard,
                ),
                const SizedBox(width: 12),
                PillButton(
                  icon: Icons.edit,
                  label: 'Add Manually',
                  onTap: onAddManually,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
