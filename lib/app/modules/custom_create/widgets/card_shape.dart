import 'package:flutter/material.dart';

import '../model/card_element_model.dart';

/// Draws a `shape` element ([CardShape]) at its own size, in its tint colour
/// and opacity. Used by the editor canvas and the template preview alike, so
/// both show exactly the same picture.
class CardShapeView extends StatelessWidget {
  const CardShapeView({super.key, required this.element});

  final CardElement element;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: element.width,
      height: element.height,
      child: CustomPaint(
        painter: CardShapePainter(
          kind: element.symbol,
          color: element.tintColor.withValues(alpha: element.opacity),
        ),
      ),
    );
  }
}

class CardShapePainter extends CustomPainter {
  const CardShapePainter({required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final contours = CardShape.polygonContours(kind);
    final dashes = CardShape.dashes(kind);
    if (contours != null) {
      final path = Path()..fillType = PathFillType.evenOdd;
      for (final c in contours) {
        path.addPolygon(
          [for (final p in c) Offset(p.dx * size.width, p.dy * size.height)],
          true,
        );
      }
      canvas.drawPath(path, paint);
    } else if (dashes != null) {
      final (dash, gap) = dashes;
      var y = 0.0;
      while (y < size.height) {
        final end = (y + dash).clamp(0.0, size.height);
        canvas.drawRect(Rect.fromLTRB(0, y, size.width, end), paint);
        y += dash + gap;
      }
    } else if (kind == CardShape.ellipse) {
      canvas.drawOval(Offset.zero & size, paint);
    } else {
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(CardShapePainter old) =>
      old.kind != kind || old.color != color;
}
