import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Clixa's picture. It is one of the expert images until it has its own.
const kClixaAvatarAsset = 'assets/images/clixa.png';

/// The five experts of the panel, in order.
const kExpertAssets = [
  'assets/images/expert_panel_5.png',
  'assets/images/expert_panel_4.png',
  'assets/images/expert_panel_3.png',
  'assets/images/expert_panel_2.png',
  'assets/images/expert_panel_1.png',
];

/// A round picture from the assets. While an image is missing (or loading) a
/// soft circle with a person icon stands in, so the layout never changes.
class RoundAsset extends StatelessWidget {
  const RoundAsset({
    super.key,
    required this.asset,
    required this.size,
    this.ring = false,
    this.radius,
  });

  final String asset;
  final double size;

  /// A white ring, so overlapped pictures stay separate.
  final bool ring;

  /// A rounded square with this corner radius instead of a circle.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final shape = radius == null
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius!));
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        shape: shape,
        color: AppColors.primarySoft,
        // The ring is drawn by the outer container's border.
      ),
      foregroundDecoration: ring
          ? ShapeDecoration(
              shape: radius == null
                  ? const CircleBorder(
                      side: BorderSide(color: Colors.white, width: 2),
                    )
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radius!),
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
            )
          : null,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => Icon(
            Icons.person_rounded,
            size: size * 0.6,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Clixa's avatar.
class ClixaAvatar extends StatelessWidget {
  const ClixaAvatar({super.key, required this.size, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) =>
      RoundAsset(asset: kClixaAvatarAsset, size: size, radius: radius);
}

/// The five experts as overlapping circles.
class ExpertAvatars extends StatelessWidget {
  const ExpertAvatars({super.key, this.size = 34, this.overlap = 10});

  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final step = size - overlap;
    return SizedBox(
      width: step * (kExpertAssets.length - 1) + size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < kExpertAssets.length; i++)
            PositionedDirectional(
              start: step * i,
              child: RoundAsset(asset: kExpertAssets[i], size: size, ring: true),
            ),
        ],
      ),
    );
  }
}
