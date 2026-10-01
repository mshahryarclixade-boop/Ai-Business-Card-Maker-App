import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// The bracketed frame overlaid on the camera preview, plus the
/// "Auto-detecting card..." status pill and the instruction pill beneath it.
class ScanFrameOverlay extends StatelessWidget {
  final double width;
  final double height;

  /// True while we're actively scanning/awaiting a detection; false once
  /// something has been captured and we're processing it.
  final bool isScanning;

  final String statusText;
  final String instructionText;
  final String? instructionSubtext;

  const ScanFrameOverlay({
    super.key,
    required this.width,
    required this.height,
    required this.instructionText,
    this.instructionSubtext,
    this.isScanning = true,
    this.statusText = 'Auto-detecting card...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _CornerBracketsPainter(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        _buildStatusPill(),
        const SizedBox(height: 12),
        _buildInstructionPill(),
      ],
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: isScanning
                ? const CircularProgressIndicator(
              strokeWidth: 1.6,
              color: AppColors.primary,
            )
                : Icon(Icons.check_circle, size: 12, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            instructionText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          if (instructionSubtext != null) ...[
            const SizedBox(height: 4),
            Text(
              instructionSubtext!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Draws four L-shaped corner brackets around a rounded rectangle,
/// the classic "align within this frame" scanner affordance.
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double radius;

  _CornerBracketsPainter({
    required this.color,
    this.cornerLength = 26,
    this.strokeWidth = 3.4,
    this.radius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Faint full outline so the frame reads clearly even between brackets.
    final outlinePaint = Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
      outlinePaint,
    );

    // Top-left
    canvas.drawArc(
      Rect.fromCircle(center: Offset(rect.left + radius, rect.top + radius), radius: radius),
      3.14159,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(rect.left, rect.top + radius), Offset(rect.left, rect.top + radius + cornerLength), paint);
    canvas.drawLine(Offset(rect.left + radius, rect.top), Offset(rect.left + radius + cornerLength, rect.top), paint);

    // Top-right
    canvas.drawArc(
      Rect.fromCircle(center: Offset(rect.right - radius, rect.top + radius), radius: radius),
      -1.5708,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(rect.right, rect.top + radius), Offset(rect.right, rect.top + radius + cornerLength), paint);
    canvas.drawLine(Offset(rect.right - radius, rect.top), Offset(rect.right - radius - cornerLength, rect.top), paint);

    // Bottom-left
    canvas.drawArc(
      Rect.fromCircle(center: Offset(rect.left + radius, rect.bottom - radius), radius: radius),
      1.5708,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(rect.left, rect.bottom - radius), Offset(rect.left, rect.bottom - radius - cornerLength), paint);
    canvas.drawLine(Offset(rect.left + radius, rect.bottom), Offset(rect.left + radius + cornerLength, rect.bottom), paint);

    // Bottom-right
    canvas.drawArc(
      Rect.fromCircle(center: Offset(rect.right - radius, rect.bottom - radius), radius: radius),
      0,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(Offset(rect.right, rect.bottom - radius), Offset(rect.right, rect.bottom - radius - cornerLength), paint);
    canvas.drawLine(Offset(rect.right - radius, rect.bottom), Offset(rect.right - radius - cornerLength, rect.bottom), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color;
}
