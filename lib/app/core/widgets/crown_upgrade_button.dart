import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_colors.dart';

class CrownUpgradeButton extends StatefulWidget {
  const CrownUpgradeButton({
    super.key,
    required this.onTap,
    this.size = 40,
    this.iconSize = 22,
    this.borderRadius = 12,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  State<CrownUpgradeButton> createState() => _CrownUpgradeButtonState();
}

class _CrownUpgradeButtonState extends State<CrownUpgradeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat(reverse: true);

    _rotation = Tween<double>(
      begin: -0.06,
      end: 0.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        // Its own repaint layer: the endless wobble must not repaint the screen
        // (and everything on it) 60 times a second.
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _rotation,
            child: FaIcon(
              FontAwesomeIcons.crown,
              size: widget.iconSize,
              color: AppColors.crownGold,
            ),
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotation.value,
                alignment: Alignment.center,
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}
