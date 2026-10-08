import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NavItem {
  final String iconAsset;
  final String label;

  const NavItem({
    required this.iconAsset,
    required this.label,
  });
}

const String _navIconsPath = 'assets/icons/bottom_nav_icons';

const List<NavItem> mainNavItems = [
  NavItem(
    iconAsset: '$_navIconsPath/home.png',
    label: 'Home',
  ),
  NavItem(
    iconAsset: 'assets/icons/scan.png',
    label: 'Scan',
  ),
  NavItem(
    iconAsset: '$_navIconsPath/contacts.png',
    label: 'Contacts',
  ),
];

// Animation tuning (only motion, no visual change)
const Duration _kSlideDuration = Duration(milliseconds: 320);
const Duration _kColorDuration = Duration(milliseconds: 220);
const Curve _kSlideCurve = Curves.easeOutCubic;

// Active indicator size.
const double _kIndicatorW = 73;
const double _kIndicatorH = 46;
const double _kBarHeight = 62;

// Width of the whole bar.
const double _kBarWidth = 280;

// Minimum gap kept between the indicator and neighbouring tabs.
const double _kIndicatorSideGap = -6;

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kBarWidth,
      height: _kBarHeight,
      child: _Pill(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _Pill({
    required this.currentIndex,
    required this.onTabSelected,
  });

  void _handleTap(int index) {
    if (index == currentIndex) return;

    HapticFeedback.selectionClick();
    onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.bottomNavBg,
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth =
              constraints.maxWidth / mainNavItems.length;

          final indicatorW = math.min(
            _kIndicatorW,
            tabWidth - _kIndicatorSideGap,
          );

          final indicatorLeft =
              (tabWidth * currentIndex) +
                  (tabWidth - indicatorW) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: _kSlideDuration,
                curve: _kSlideCurve,
                left: indicatorLeft,
                top: (_kBarHeight - _kIndicatorH) / 2,
                width: indicatorW,
                height: _kIndicatorH,
                child: const RepaintBoundary(
                  child: _ActiveIndicator(),
                ),
              ),

              Row(
                children: List.generate(
                  mainNavItems.length,
                      (index) {
                    final item = mainNavItems[index];
                    final isActive = index == currentIndex;

                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isActive,
                        label: item.label,
                        child: GestureDetector(
                          onTap: () => _handleTap(index),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: _NavItemContent(
                              item: item,
                              isActive: isActive,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveIndicator extends StatelessWidget {
  const _ActiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: const _OutsideOnlyClipper(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(96.31),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x33CACAEF),
              borderRadius: BorderRadius.circular(96.31),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItemContent extends StatelessWidget {
  final NavItem item;
  final bool isActive;

  const _NavItemContent({
    required this.item,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.bottomselcted
        : AppColors.bottomNavInactive;

    // Scan icon is larger than Home and Contacts.
    final double iconSize = item.label == 'Scan' ? 22 : 16;

    return SizedBox(
      width: 65,
      height: 46,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: _kColorDuration,
              curve: Curves.easeOut,
              builder: (context, animatedColor, _) {
                return Image.asset(
                  item.iconAsset,
                  color: animatedColor,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                );
              },
            ),
          ),
          const SizedBox(height: 5.78),
          SizedBox(
            width: 61,
            child: AnimatedDefaultTextStyle(
              duration: _kColorDuration,
              curve: Curves.easeOut,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.3,
                color: color,
              ),
              child: Text(item.label),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutsideOnlyClipper extends CustomClipper<Path> {
  const _OutsideOnlyClipper();

  @override
  Path getClip(Size size) {
    final pill = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );

    return Path.combine(
      PathOperation.difference,
      Path()
        ..addRect(
          Rect.fromLTWH(
            -20,
            -20,
            size.width + 40,
            size.height + 40,
          ),
        ),
      Path()..addRRect(pill),
    );
  }

  @override
  bool shouldReclip(
      covariant CustomClipper<Path> oldClipper,
      ) {
    return false;
  }
}