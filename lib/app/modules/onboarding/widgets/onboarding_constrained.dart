import 'package:flutter/material.dart';

const double kOnboardingMaxWidth = 480;

bool isTabletWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

class OnboardingConstrained extends StatelessWidget {
  const OnboardingConstrained({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kOnboardingMaxWidth),
        child: child,
      ),
    );
  }
}