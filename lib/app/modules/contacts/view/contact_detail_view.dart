import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/contacts_controller.dart';
import '../model/contact_model.dart';
import '../widgets/company_info_card.dart';
import '../widgets/contact_info_card.dart';
import 'add_contact_view.dart';
import '../widgets/info_row.dart';
import '../widgets/photo_header.dart';

class ContactDetailView extends StatelessWidget {
  final ContactModel contact;

  const ContactDetailView({super.key, required this.contact});

  // How much the white card overlaps the bottom of the photo.
  static const double _overlap = 15;
  // Height reserved for the top row (back / edit buttons) inside PhotoHeader.
  static const double _topRowHeight = 8 + 40; // padding + button size
  static const double _spacingAfterRow = 8;
  static const double _photoHeight = 330;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ContactsController>(tag: 'contacts');
    final topInset = MediaQuery.of(context).padding.top;

    // Total height PhotoHeader actually occupies (status bar + row + photo).
    final headerHeight =
        topInset + _topRowHeight + _spacingAfterRow + _photoHeight;

    // Where the white card should start, to overlap the photo by `_overlap`.
    final cardTop = headerHeight - _overlap;

    return Scaffold(
      backgroundColor: AppColors.contactsScaffoldBg,
      body: Obx(() {
        final current = controller.contacts.firstWhere(
              (c) => c.id == contact.id,
          orElse: () => contact,
        );

        final infoRows = <Widget>[
          if (current.email.isNotEmpty)
            InfoRow(icon: Icons.mail, text: current.email),
          if (current.phone.isNotEmpty)
            InfoRow(icon: Icons.call, text: current.phone),
          if (current.website.isNotEmpty)
            InfoRow(icon: Icons.language, text: current.website),
          if (current.linkedin.isNotEmpty)
            InfoRow(icon: Icons.link, text: current.linkedin),
        ];

        final companyInfoRows = <Widget>[
          if (current.companyEmail.isNotEmpty)
            InfoRow(icon: Icons.mail, text: current.companyEmail),
          if (current.companyLinkedin.isNotEmpty)
            InfoRow(icon: Icons.link, text: current.companyLinkedin),
          if (current.companyAddress.isNotEmpty)
            InfoRow(icon: Icons.location_on, text: current.companyAddress),
        ];

        return Stack(
          children: [
            // Backdrop: photo header, sits behind the card, unaffected
            // by any overlap math.
            PhotoHeader(
              contact: current,
              onBack: () => Get.back(),
              onEdit: () => Get.to(
                    () => AddContactView(existing: current),
                transition: Transition.rightToLeft,
              ),
            ),

            // White card: positioned explicitly from `cardTop` down to
            // the literal bottom of the screen (bottom: 0). No gap is
            // possible because this box's layout position — not just
            // its paint — is what's being set.
            Positioned(
              top: cardTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      offset: Offset(0, 1),
                      blurRadius: 4.4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(23, 10, 23, 20),
                  // Scrollable so a contact with lots of fields never
                  // overflows — it scrolls instead.
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            current.fullName,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.contactsTitleDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        CompanyInfoCard(
                          companyName: current.companyName,
                          jobTitle: current.jobTitle,
                        ),

                        if (infoRows.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ContactInfoCard(rows: infoRows),
                        ],

                        if (companyInfoRows.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ContactInfoCard(rows: companyInfoRows),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}