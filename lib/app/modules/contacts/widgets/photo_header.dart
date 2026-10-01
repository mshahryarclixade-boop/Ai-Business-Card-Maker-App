import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/contact_model.dart';
import 'round_icon_button.dart';

class PhotoHeader extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const PhotoHeader({
    super.key,
    required this.contact,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        contact.imagePath != null && File(contact.imagePath!).existsSync();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back,
                  onTap: onBack,
                ),
                Expanded(
                  child: Text(
                    'Contacts',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.contactsTitleDark,
                    ),
                  ),
                ),
                RoundIconButton(
                  icon: Icons.edit,
                  onTap: onEdit,
                ),
              ],
            ),
          ),

          // Padding above the photo.
          const SizedBox(height: 8),

          // Reduced-size photo.
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: SizedBox(
              width: double.infinity,
              height: 335,
              child: hasPhoto
                  ? Image.file(
                File(contact.imagePath!),
                fit: BoxFit.cover,
              )
                  : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.contactsPhotoGradientStart,
                      AppColors.contactsPhotoGradientEnd,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Text(
                    contact.initials,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}