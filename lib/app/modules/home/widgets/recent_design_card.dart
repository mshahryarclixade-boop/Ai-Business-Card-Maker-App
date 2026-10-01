import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RecentDesignCard extends StatelessWidget {
  final File? thumbnailFile;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// --- additions for the My Cards / Favorite list use-case ---
  /// Show the heart badge (top-right) at all.
  final bool showFavoriteBadge;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool isPremium;
  final double aspectRatio;

  const RecentDesignCard({
    super.key,
    this.thumbnailFile,
    this.gradient,
    this.onTap,
    this.onLongPress,
    this.showFavoriteBadge = false,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.isPremium = false,
    this.aspectRatio = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: thumbnailFile == null
                    ? (gradient ??
                    const LinearGradient(
                      colors: [Colors.transparent, Colors.transparent],
                    ))
                    : null,
                borderRadius: BorderRadius.circular(3),
                image: thumbnailFile != null
                    ? DecorationImage(
                  image: FileImage(thumbnailFile!),
                  fit: BoxFit.cover,
                )
                    : null,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            if (showFavoriteBadge)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.favorite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            if (isPremium)
              const Positioned(
                bottom: 8,
                right: 8,
                child: Icon(
                  Icons.emoji_events, // swap for the crown asset icon
                  color: AppColors.crownGold,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}