import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/template_item.dart';

/// Large preview of a single template

class TemplatePreviewCard extends StatelessWidget {
  final TemplateItem item;

  const TemplatePreviewCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Side(imagePath: item.frontImagePath),
        const SizedBox(height: 18),
        _Side(imagePath: item.backImagePath),
      ],
    );
  }
}

/// One side (front or back) of the preview — sized to the image's own
/// natural aspect ratio, not a fixed orientation ratio.
class _Side extends StatelessWidget {
  final String imagePath;

  const _Side({required this.imagePath});

  static const double _cornerRadius = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Shadow lives on this outer Container (not the ClipRRect below),
      // since a clipped widget can't cast its own shadow.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: SizedBox(
          // Width fixed to available space, height intentionally NOT
          // set — Image.asset below will size itself to match the
          // image's real aspect ratio at that width.
          width: double.infinity,
          child: Image.asset(
            imagePath,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              // Only the broken-image placeholder needs an explicit
              // height, since there's no real image to derive one from.
              height: 160,
              color: const Color(0xFFE4E2F2),
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined, color: AppColors.pillLabelGrey, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}