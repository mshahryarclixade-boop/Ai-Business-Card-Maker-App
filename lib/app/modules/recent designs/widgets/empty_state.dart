import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class EmptyStateView extends StatelessWidget {
  /// Path to the card icon asset, e.g. 'assets/icons/mycardicon.png'.
  final String iconAsset;

  /// Optional background illustration behind the icon
  /// (e.g. 'assets/icons/mycardbg.png'). Leave null for no background —
  /// used by the Saved tab, which shows just the plain icon.
  final String? backgroundAsset;

  /// Shows a small heart badge over the top-right of the icon.
  /// Used by the Favorite tab's empty state.
  final bool showHeartBadge;

  /// Size (width & height) of the icon image itself. Defaults to 120
  /// when there's no background, 88 when there is one — pass this to
  /// override per screen instead of editing the widget.
  final double? iconSize;

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onButtonTap;

  const EmptyStateView({
    super.key,
    required this.iconAsset,
    this.backgroundAsset,
    this.showHeartBadge = false,
    this.iconSize,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.3), // <-- move up/down: -1 (top) to 1 (bottom), 0 = center
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (backgroundAsset != null)
                    Image.asset(
                      backgroundAsset!,
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  Image.asset(
                    iconAsset,
                    width: iconSize ?? (backgroundAsset != null ? 88 : 100),
                    height: iconSize ?? (backgroundAsset != null ? 88 : 120),
                    fit: BoxFit.contain,
                  ),
                  if (showHeartBadge)
                    const Positioned(
                      top: 26,
                      right: 26,
                      child: _HeartBadge(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onButtonTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

class _HeartBadge extends StatelessWidget {
  const _HeartBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.favorite, color: Colors.white, size: 20),
    );
  }
}