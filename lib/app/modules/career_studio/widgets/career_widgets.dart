import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';

/// Shared building blocks of the Career Studio screens (UI only).

const kCareerPagePadding = EdgeInsets.symmetric(horizontal: 20);

/// Display keys for the English goal ids used in the profile data.
const kCareerGoalKeys = {
  'Get hired': 'career_builder_goal_get_hired',
  'Win clients': 'career_builder_goal_win_clients',
  'Raise funding': 'career_builder_goal_raise_funding',
  'Build authority': 'career_builder_goal_build_authority',
};

/// Jumping back to the Career Studio hub from deep in a flow.
abstract final class CareerNav {
  /// Route name of the open hub (set by the hub itself).
  static String? hubRoute;

  /// Pops everything above the Career Studio hub (or to the first route when
  /// the hub isn't on the stack).
  static void toHub() {
    final name = hubRoute;
    Get.until((r) => name != null ? r.settings.name == name : r.isFirst);
  }
}

/// "Coming soon" notice for buttons whose backend isn't built yet.
void careerComingSoon() => Get.snackbar(
  'career_coming_soon_title'.tr,
  'career_coming_soon_message'.tr,
  snackPosition: SnackPosition.BOTTOM,
  margin: const EdgeInsets.all(15),
);

/// Back arrow + centred title (+ optional trailing widget).
class CareerAppBar extends StatelessWidget {
  const CareerAppBar({
    super.key,
    required this.title,
    this.trailing,
    this.leadingIcon = Icons.arrow_back_rounded,
    this.onLeading,
    this.titleInset = 0,
  });

  final String title;
  final Widget? trailing;

  /// Gap kept between the title and its neighbours (back arrow, trailing
  /// widget). When set, the title is centred in the space between them and
  /// shrinks to fit instead of running under a wide trailing widget. 0 = no
  /// change: the title stays centred on the screen.
  final double titleInset;

  /// Defaults to the back arrow (which mirrors in RTL); [onLeading] defaults
  /// to popping the route.
  final IconData leadingIcon;
  final VoidCallback? onLeading;

  Widget get _title => Text(
    title,
    maxLines: titleInset > 0 ? 1 : null,
    style: const TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.titleDark,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final back = IconButton(
      onPressed: onLeading ?? () => Navigator.of(context).maybePop(),
      icon: Icon(leadingIcon, size: 24, color: AppColors.titleDark),
      padding: const EdgeInsetsDirectional.only(start: 20),
      constraints: const BoxConstraints(),
    );

    if (titleInset > 0) {
      return SizedBox(
        height: 56,
        child: Row(
          children: [
            back,
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: titleInset),
                child: FittedBox(fit: BoxFit.scaleDown, child: _title),
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 20),
                child: trailing,
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(alignment: AlignmentDirectional.centerStart, child: back),
          _title,
          if (trailing != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 20),
                child: trailing,
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-width filled action button at the bottom of a screen.
class CareerPrimaryButton extends StatelessWidget {
  const CareerPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.onboardingBtnEnd,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

/// Small rounded tag (Headline, About, ...).
class CareerTag extends StatelessWidget {
  const CareerTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.onboardingBtnEnd,
        ),
      ),
    );
  }
}

/// Rounded square holding a feature icon.
class CareerIconTile extends StatelessWidget {
  const CareerIconTile(this.icon, {super.key, this.dark = false});

  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: dark ? AppColors.primaryDark : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: dark ? Colors.white : AppColors.onboardingBtnEnd,
      ),
    );
  }
}

/// Dashed rounded outline around [child].
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.color = AppColors.dotInactive,
    this.radius = 14,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
