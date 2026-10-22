import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Circular score gauge with the number (and an optional caption) inside.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 84,
    this.caption,
    this.faded = false,
  });

  final int score;
  final double size;

  /// Small text under the number ("expected", "before", "now").
  final String? caption;

  /// The lighter "before" look.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final color = faded
        ? AppColors.onboardingBtnEnd.withValues(alpha: 0.45)
        : AppColors.onboardingBtnEnd;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: size * 0.11,
              backgroundColor: AppColors.profileStepInactive,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: size * 0.32,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: faded ? AppColors.textGrey : AppColors.titleDark,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E6888),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Before -> after rings joined by an arrow (mirrors in right-to-left).
class ScoreBeforeAfter extends StatelessWidget {
  const ScoreBeforeAfter({
    super.key,
    required this.before,
    required this.after,
    this.beforeCaption,
    this.afterCaption,
  });

  final int before;
  final int after;
  final String? beforeCaption;
  final String? afterCaption;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScoreRing(
          score: before,
          size: 70,
          faded: true,
          caption: beforeCaption,
        ),
        const SizedBox(width: 18),
        const Icon(
          Icons.arrow_forward_rounded,
          size: 22,
          color: AppColors.onboardingBtnEnd,
        ),
        const SizedBox(width: 18),
        ScoreRing(score: after, size: 88, caption: afterCaption),
      ],
    );
  }
}
