import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class FeatureItem {
  // Can be either an IconData or an asset image path.
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const FeatureItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class FeatureGrid extends StatelessWidget {
  final List<FeatureItem> items;

  const FeatureGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // Get the available width of the screen.
    final screenWidth = MediaQuery.of(context).size.width;

    // Keep the same horizontal spacing while allowing
    // the four tiles to resize according to the screen width.
    const spacing = 11.91;
    final availableWidth = screenWidth - 46;

    final tileWidth =
        (availableWidth - (spacing * (items.length - 1))) / items.length;

    return SizedBox(
      width: availableWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            SizedBox(
              width: tileWidth,
              height: 76.67,
              child: _FeatureTile(item: items[i]),
            ),
            if (i != items.length - 1) const SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final FeatureItem item;

  const _FeatureTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: double.infinity,
        height: 76.67,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.iconTileBg,
          borderRadius: BorderRadius.circular(9.68),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, 0.74),
              blurRadius: 32.53,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Show an asset image when a String path is provided,
            // otherwise show the normal IconData.
            if (item.icon is String)
              Image.asset(
                item.icon as String,
                width: 19.54,
                height: 20.85,
                fit: BoxFit.contain,
              )
            else
              Icon(item.icon as IconData, size: 22, color: AppColors.primary),

            const SizedBox(height: 6),

            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.titleDark,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
