import 'dart:ui';
import 'package:flutter/material.dart';

class OnboardingBottomShadow extends StatelessWidget {
  final double width;
  final double height;
  final double gap;

  const OnboardingBottomShadow({
    super.key,
    this.width = 310,
    this.height = 15,
    this.gap = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: -(gap + height),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(color: Color(0xFF918AC0)),
        ),
      ),
    );
  }
}