import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fits a paywall that is laid out on a fixed 393 x 860 canvas to any screen.
///
/// - Phones of the design size and up, and tablets: the whole canvas is scaled
///   to fit (width and height), centred, so nothing is cut off and a tablet
///   gets a larger, centred paywall instead of a stretched one.
/// - Short or narrow phones: the canvas is never shrunk below
///   [minReadableScale] (the text would become too small to read); the screen
///   scrolls vertically for the rest instead.
class PaywallCanvas extends StatelessWidget {
  const PaywallCanvas({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.child,
  });

  final double designWidth;
  final double designHeight;

  /// The paywall, laid out on a [designWidth] x [designHeight] canvas.
  final Widget child;

  static const minReadableScale = 0.82;
  static const maxScale = 1.6;

  /// The scale used on a [width] x [height] area.
  static double scaleFor(
    double width,
    double height, {
    double designWidth = 393,
    double designHeight = 860,
  }) {
    final byWidth = width / designWidth;
    final fit = math.min(byWidth, height / designHeight);
    final scale = fit >= minReadableScale
        ? fit
        : math.max(fit, math.min(byWidth, minReadableScale));
    return math.min(scale, maxScale);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final scale = scaleFor(
          c.maxWidth,
          c.maxHeight,
          designWidth: designWidth,
          designHeight: designHeight,
        );
        final w = designWidth * scale;
        final h = designHeight * scale;
        return SingleChildScrollView(
          physics: h <= c.maxHeight
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Center(
              child: SizedBox(
                width: w,
                height: h,
                child: FittedBox(
                  fit: BoxFit.fill,
                  // The canvas is laid out in pixels: the system text size must
                  // not enlarge its text (it overflowed at 1.4x).
                  child: MediaQuery.withNoTextScaling(
                    child: SizedBox(
                      width: designWidth,
                      height: designHeight,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
