import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';

import 'color_palette.dart';
import '../controller/card_editor_controller.dart';
import '../controller/card_editor_symbols_controller_ext.dart';

/// The color + opacity (+ optional size) editor shown once a sticker is
/// placed on the canvas. Used identically by the Social, Arrow and Icons
/// tabs — same [ColorPaletteGrid] as everywhere else in the app, per the
/// "one palette, don't repeat it per filter" note.
class ElementAdjustPanel extends StatelessWidget {
  final CardEditorController controller;
  final bool showSizeSlider;

  const ElementAdjustPanel({
    super.key,
    required this.controller,
    this.showSizeSlider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedId = controller.selectedElementId.value;
      if (selectedId == null) return const SizedBox.shrink();

      final selected =
      controller.elements.firstWhereOrNull((e) => e.id == selectedId);
      if (selected == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorPaletteGrid(
              selected: selected.tintColor,
              onSelect: controller.setSelectedTint,
              onOpenCustomPicker: () => controller.openColorPicker(
                target: ColorPickerTarget.element,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Opacity',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A8A93)),
            ),
            Slider(
              value: selected.opacity,
              min: 0.1,
              max: 1.0,
              activeColor: const Color(0xFFFFCC00),
              onChanged: controller.setSelectedOpacity,
            ),
            if (showSizeSlider) ...[
              const Text(
                'Size',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A8A93)),
              ),
              Slider(
                value: selected.height.clamp(16, 140),
                min: 16,
                max: 140,
                activeColor: const Color(0xFFFFCC00),
                onChanged: controller.setSelectedStickerSize,
              ),
            ],
          ],
        ),
      );
    });
  }
}
