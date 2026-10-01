import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/contact_model.dart';
import '../service/contact_export_service.dart';

enum _ContactAction { saveToDevice, share }

/// Horizontal "..." button with "Save to device" and "Share".
/// Put it right before the ">" arrow on a contact card.
class ContactActionsMenu extends StatelessWidget {
  final ContactModel contact;

  const ContactActionsMenu({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ContactAction>(
      tooltip: '',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: const Icon(
        Icons.more_horiz,
        color: AppColors.contactsSubtitleGrey,
        size: 22,
      ),
      onSelected: (action) {
        switch (action) {
          case _ContactAction.saveToDevice:
            ContactExportService.saveToDevice(contact);
            break;
          case _ContactAction.share:
            ContactExportService.share(contact);
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ContactAction.saveToDevice,
          child: _MenuRow(icon: Icons.save_alt_rounded, label: 'Save to device'),
        ),
        PopupMenuItem(
          value: _ContactAction.share,
          child: _MenuRow(icon: Icons.share_outlined, label: 'Share'),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.contactsTitleDark,
          ),
        ),
      ],
    );
  }
}