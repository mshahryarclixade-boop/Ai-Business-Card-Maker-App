
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../model/card_element_model.dart';

/// Pure-geometry clip paths for the Shapes tab — no mask-image assets
/// needed. Add a case here if you add more shapes to [CardImageMask].
class ImageMaskClipper extends CustomClipper<Path> {
  final CardImageMask mask;
  const ImageMaskClipper(this.mask);

  @override
  Path getClip(Size size) {
    switch (mask) {
      case CardImageMask.none:
        return Path()..addRect(Offset.zero & size);
      case CardImageMask.circle:
        return Path()..addOval(Offset.zero & size);
      case CardImageMask.roundedSquare:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Offset.zero & size, Radius.circular(size.shortestSide * 0.18)));
      case CardImageMask.hexagon:
        return _polygon(size, sides: 6, rotationDeg: -90);
      case CardImageMask.star:
        return _star(size);
      case CardImageMask.cloud1:
        return _cloud(size, puffCount: 5);
      case CardImageMask.cloud2:
        return _cloud(size, puffCount: 7);
    }
  }

  Path _polygon(Size size, {required int sides, double rotationDeg = 0}) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    for (var i = 0; i < sides; i++) {
      final angle = (rotationDeg + i * 360 / sides) * math.pi / 180;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  Path _star(Size size, {int points = 5}) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.45;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = (-90 + i * 180 / points) * math.pi / 180;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  /// A soft "cloud" silhouette made of overlapping arcs along the top and
  /// a rounded base. Approximate rather than pixel-perfect — swap in an
  /// asset-based mask later if you need an exact cloud outline.
  Path _cloud(Size size, {required int puffCount}) {
    final path = Path();
    final baseY = size.height * 0.72;
    path.moveTo(size.width * 0.12, baseY);
    for (var i = 0; i < puffCount; i++) {
      final t = i / (puffCount - 1);
      final cx = size.width * (0.12 + t * 0.76);
      final r = size.width / (puffCount * 1.3);
      final lift = size.height * 0.1 * math.sin(t * math.pi);
      path.arcToPoint(
        Offset(cx + r, baseY - lift),
        radius: Radius.circular(r),
        clockwise: true,
      );
      path.arcToPoint(
        Offset(cx + r * 1.6, baseY),
        radius: Radius.circular(r),
        clockwise: true,
      );
    }
    path.lineTo(size.width * 0.88, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.98,
      size.width * 0.12,
      size.height * 0.85,
    );
    return path..close();
  }

  @override
  bool shouldReclip(covariant ImageMaskClipper oldClipper) => oldClipper.mask != mask;
}
