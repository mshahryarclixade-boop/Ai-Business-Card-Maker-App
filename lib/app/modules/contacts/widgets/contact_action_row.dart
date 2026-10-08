import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/contact_model.dart';
import '../service/contact_export_service.dart';
import '../service/contact_follow_up_service.dart';
import 'pill_button.dart';

/// Quick actions under the contact's name. Only actions that can work for
/// this contact are shown (no email address, no Email button).
class ContactActionRow extends StatelessWidget {
  final ContactModel contact;

  const ContactActionRow({super.key, required this.contact});

  void _onMessage(BuildContext context) {
    final hasWhatsApp =
        ContactFollowUpService.whatsappNumber(contact) != null;

    if (!hasWhatsApp) {
      ContactFollowUpService.sendSms(contact);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send Message',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.contactsTitleDark,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PillButton(
                  icon: Icons.sms_outlined,
                  label: 'SMS',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ContactFollowUpService.sendSms(contact);
                  },
                ),
                const SizedBox(width: 12),
                PillButton(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ContactFollowUpService.sendWhatsApp(contact);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canMessage = ContactFollowUpService.smsNumber(contact) != null;
    final canEmail = ContactFollowUpService.email(contact) != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (canMessage)
          _ActionItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message',
            onTap: () => _onMessage(context),
          ),
        if (canEmail)
          _ActionItem(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            onTap: () => ContactFollowUpService.sendEmail(contact),
          ),
        _ActionItem(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () => ContactExportService.share(contact),
        ),
        _ActionItem(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Save to Phone',
          onTap: () => ContactExportService.saveToDevice(contact),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.contactsLavenderBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.contactsLavenderBorder),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.contactsTitleDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}