import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/contact_model.dart';
import 'avatar_widget.dart';
import 'confirm_delete_contact.dart';
import 'contact_actions_menu.dart';

class ContactCard extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onDelete,
  });

  Future<bool> _confirmDelete(BuildContext context) =>
      confirmDeleteContact(context);

  /// Company shown under the name (job title if there is no company).
  String get _companyLine => contact.companyName.trim().isNotEmpty
      ? contact.companyName.trim()
      : contact.jobTitle.trim();

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(contact.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(right: 0),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AvatarWidget(contact: contact, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.fullName,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.contactsTitleDark,
                        ),
                      ),
                      if (_companyLine.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _companyLine,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              color: AppColors.contactsSubtitleGrey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ContactActionsMenu(contact: contact),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.contactsSubtitleGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}