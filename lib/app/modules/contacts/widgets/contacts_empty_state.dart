import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'pill_button.dart';
import '../../../core/translations/tr_extension.dart';

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
            Text('contacts_empty_title'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.contactsTitleDark,
              ),
            ),
            const SizedBox(height: 3),
            Text('contacts_empty_subtitle'.tr,
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
                Flexible(child: PillButton(
                  icon: Icons.document_scanner_outlined,
                  label: 'contacts_scan_card'.tr,
                  onTap: onScanCard,
                )),
                const SizedBox(width: 12),
                Flexible(child: PillButton(
                  icon: Icons.edit,
                  label: 'contacts_add_manually'.tr,
                  onTap: onAddManually,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
