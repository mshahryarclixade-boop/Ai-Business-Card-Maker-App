import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../model/contact_model.dart';

/// Circular avatar that shows the saved photo, or falls back to initials.
class AvatarWidget extends StatelessWidget {
  final ContactModel contact;
  final double size;

  const AvatarWidget({
    super.key,
    required this.contact,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final path = contact.imagePath;

    if (path != null && File(path).existsSync()) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: FileImage(
          File(path),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.contactsLavenderBg,
      child: Text(
        contact.initials,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
