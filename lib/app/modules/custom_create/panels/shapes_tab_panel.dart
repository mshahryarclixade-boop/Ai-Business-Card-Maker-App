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
    CardImageMask.hexagon,
    CardImageMask.star,
    CardImageMask.cloud1,
    CardImageMask.cloud2,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _masks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final mask = _masks[i];
          return GestureDetector(
            onTap: () => controller.applyImageMask(mask),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipPath(
                  clipper: ImageMaskClipper(mask),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFBEE3F8), Color(0xFF9BD59C)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mask.label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6B6B76)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
