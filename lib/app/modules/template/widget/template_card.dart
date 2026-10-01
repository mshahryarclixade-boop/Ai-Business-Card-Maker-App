import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../model/template_item.dart';

/// Grid card used in the templates listing.

class TemplateCard extends StatelessWidget {
  final TemplateItem item;
  final bool isSaved;
  final VoidCallback onHeartTap;
  final VoidCallback onTap;

  const TemplateCard({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onHeartTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tapping only ever passes the item forward — the detail screen
      // pulls front+back straight off this same TemplateItem.
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Stack(
          children: [
            Image.asset(
              item.frontImagePath,
              width: double.infinity,
              // contain, not cover — full card design shown, height
              // follows the image's own ratio instead of a fixed one.
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 160,
                color: const Color(0xFFE4E2F2),
                alignment: Alignment.center,
                child: const Icon(Icons.image_outlined, color: AppColors.pillLabelGrey, size: 28),
              ),
            ),
            if (item.isPremium)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.crown, size: 12, color: Color(0xFFF5A623)),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onHeartTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    size: 14,
                    color: isSaved ? Colors.redAccent : AppColors.pillLabelGrey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}