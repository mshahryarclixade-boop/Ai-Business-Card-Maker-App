import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../scan card and qr/view/scan_card_view.dart';

class NavItem {
  final String iconAsset;
  final String label;

  const NavItem({required this.iconAsset, required this.label});
}

const String _navIconsPath = 'assets/icons/bottom_nav_icons';

const List<NavItem> mainNavItems = [
  NavItem(iconAsset: '$_navIconsPath/home.png', label: 'Home'),
  NavItem(iconAsset: '$_navIconsPath/templates.png', label: 'Template'),
  NavItem(iconAsset: '$_navIconsPath/contacts.png', label: 'Contacts'),
  NavItem(iconAsset: '$_navIconsPath/profile.png', label: 'Profile'),
];

// Animation tuning (only motion, no visual change)
const Duration _kSlideDuration = Duration(milliseconds: 320);
const Duration _kColorDuration = Duration(milliseconds: 220);
const Curve _kSlideCurve = Curves.easeOutCubic;

// Active indicator size. Width is the MAXIMUM: on narrow screens it shrinks
// so it never spills outside its own tab (see _Pill).
const double _kIndicatorW = 73;
const double _kIndicatorH = 54;
const double _kBarHeight = 70;

// Minimum gap kept between the indicator and the neighbouring tabs.
const double _kIndicatorSideGap = -6;

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScanTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kBarHeight,
      child: Row(
        children: [
          Expanded(
            child: _Pill(
              currentIndex: currentIndex,
              onTabSelected: onTabSelected,
            ),
          ),
          const SizedBox(width: 3),
          _ScanFab(onTap: onScanTap),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _Pill({required this.currentIndex, required this.onTabSelected});

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
          BoxShadow(color: Color(0x1A000000), blurRadius: 4),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / mainNavItems.length;

          // Indicator never gets wider than its own tab, so on narrow
          // phones it can't touch the neighbouring tab's label.
          final indicatorW = math.min(
            _kIndicatorW,
            tabWidth - _kIndicatorSideGap,
          );
          final indicatorLeft =
              (tabWidth * currentIndex) + (tabWidth - indicatorW) / 2;

          // TEMP: remove after checking on both phones.
          debugPrint(
            'NAV: tabWidth=$tabWidth  indicatorW=$indicatorW  max=$_kIndicatorW',
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // One indicator that slides between tabs (instead of
              // appearing/disappearing per tab).
              AnimatedPositioned(
                duration: _kSlideDuration,
                curve: _kSlideCurve,
                left: indicatorLeft,
                top: (_kBarHeight - _kIndicatorH) / 2,
                width: indicatorW,
                height: _kIndicatorH,
                child: const RepaintBoundary(child: _ActiveIndicator()),
              ),
              Row(
                children: List.generate(mainNavItems.length, (index) {
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
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The soft highlighted pill behind the active tab.
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
                // boxShadow: const [
                //   BoxShadow(
                //     color: Color(0x40000000),
                //     blurRadius: 3.85,
                //     offset: Offset.zero,
                //   ),
                // ],
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

  const _NavItemContent({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color =
    isActive ? AppColors.bottomselcted : AppColors.bottomNavInactive;

    return SizedBox(
      width: 65,
      height: 46,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            // Icon color smoothly fades between inactive <-> active
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
            // Label color also animates smoothly
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

class _ScanFab extends StatefulWidget {
  final VoidCallback onTap;

  const _ScanFab({required this.onTap});

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scan card',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: () {
          HapticFeedback.lightImpact();
          Get.to(
                () => const ScanCardView(),
            transition: Transition.rightToLeft,
          );
        },
        // Subtle press feedback (scale down while pressed)
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FA),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: Image.asset(
                  'assets/icons/scan.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips away the inside of the pill so only the outer shadow is visible.
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
        ..addRect(Rect.fromLTWH(-20, -20, size.width + 40, size.height + 40)),
      Path()..addRRect(pill),
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}