import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../controller/card_editor_controller.dart';
import '../widgets/color_palette.dart';
import '../widgets/panel_shared.dart';

/// The Background tool: just the colours. They change the selected element
/// (a text, a shape, an icon) or, with nothing selected, the card background.
class BackgroundToolPanel extends StatelessWidget {
  final CardEditorController controller;
  const BackgroundToolPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelHeader(title: '', onBack: controller.closeToolPanel),
          const SizedBox(height: 4),
          Obx(
            () => ColorPaletteGrid(
              // Follows the selected element; the card background otherwise.
              selected: controller.selectedElement != null
                  ? controller.toolColor
                  : (controller.backgroundImage.value == null &&
                        controller.backgroundTemplate.value == null)
                  ? controller.backgroundColor.value
                  : null,
              swatchSize: 30,
              spacing: 14,
              onSelect: controller.setToolColor,
              onOpenCustomPicker: () => controller.openColorPicker(
                target: controller.toolColorTarget,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
