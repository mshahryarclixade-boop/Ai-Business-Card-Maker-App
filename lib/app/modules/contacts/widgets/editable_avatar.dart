import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Circular contact photo with a dashed border and a small edit badge,
/// used as the "tap photo to add a picture" affordance on the
/// Add/Edit Contact screen.
class EditableAvatar extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  final double radius;

  const EditableAvatar({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.radius = 34,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && File(imagePath!).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: _DashedCirclePainter(
              color: AppColors.primary.withOpacity(0.55),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: radius,
                backgroundColor: AppColors.contactsLavenderBg,
                backgroundImage:
                hasImage ? FileImage(File(imagePath!)) : null,
                child: hasImage
                    ? null
                    : Icon(
                  Icons.person,
                  size: radius * 0.94,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: const Icon(
                Icons.edit,
                size: 11,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed circular border drawn behind the avatar.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DashedCirclePainter({
    required this.color,
    this.dashWidth = 5,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 1;

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}