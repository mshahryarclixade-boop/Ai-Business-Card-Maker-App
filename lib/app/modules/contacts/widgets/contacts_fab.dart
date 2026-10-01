import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ContactsFab extends StatelessWidget {
  final VoidCallback onTap;

  const ContactsFab({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton(
        onPressed: onTap,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: AppColors.white,
          size: 22,
        ),
      ),
    );
  }
}