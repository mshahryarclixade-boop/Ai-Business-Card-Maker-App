import 'package:flutter/material.dart';

const double kOnboardingMaxWidth = 480;
const double kOnboardingTabletMaxWidth = 720;

bool isTabletWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

class OnboardingConstrained extends StatelessWidget {
  const OnboardingConstrained({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTabletWidth(context)
              ? kOnboardingTabletMaxWidth
              : kOnboardingMaxWidth,
        ),
        child: child,
      ),
    );
  }
}

/// Fits the content into the space it is given, without scrolling: it is
/// shown at its normal size and only scaled down when the screen is too short
/// for it. On a tablet shorter content is centred vertically.
class OnboardingFit extends StatelessWidget {
  const OnboardingFit({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tablet = isTabletWidth(context);
    final maxWidth = tablet ? kOnboardingTabletMaxWidth : kOnboardingMaxWidth;
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth < maxWidth ? c.maxWidth : maxWidth;
        return Align(
          alignment: tablet ? Alignment.center : Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: tablet ? Alignment.center : Alignment.topCenter,
            child: SizedBox(width: width, child: child),
          ),
        );
      },
    );
  }
}
