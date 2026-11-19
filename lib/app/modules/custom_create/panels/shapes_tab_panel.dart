import 'package:flutter/material.dart';
import '../model/card_element_model.dart';
import '../controller/card_editor_controller.dart';
import '../controller/card_editor_symbols_controller_ext.dart';
import '../widgets/image_mask_clipper.dart';

/// Shapes tab: re-masks the selected (or latest) image element into a
/// different silhouette. Purely geometric (image_mask_clipper.dart), so
/// no extra mask assets are needed.
class ShapesTabPanel extends StatelessWidget {
  final CardEditorController controller;
  const ShapesTabPanel({super.key, required this.controller});

  static const _masks = [
    CardImageMask.circle,
    CardImageMask.roundedSquare,
    CardImageMask.rectangle,
    CardImageMask.hexagon,
    CardImageMask.star,
    CardImageMask.diamond,
    CardImageMask.pentagon,
    CardImageMask.triangle,
    CardImageMask.heart,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _masks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 26),
        itemBuilder: (_, i) {
          final mask = _masks[i];
          return GestureDetector(
            onTap: () => controller.applyImageMask(mask),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(44, 44),
                    painter: _ShapeOutlinePainter(ImageMaskClipper(mask)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mask.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B6B76),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The mask's silhouette as a thin outline with a transparent fill.
class _ShapeOutlinePainter extends CustomPainter {
  _ShapeOutlinePainter(this.clipper);

  final ImageMaskClipper clipper;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = Offset(2, 2);
    final path = clipper
        .getClip(Size(size.width - 4, size.height - 4))
        .shift(inset);
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF1E1E24),
    );
  }

  @override
  bool shouldRepaint(_ShapeOutlinePainter old) =>
      old.clipper.mask != clipper.mask;
}
