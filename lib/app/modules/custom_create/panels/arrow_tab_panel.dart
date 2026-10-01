import 'package:flutter/material.dart';
import '../model/symbol_asset_items.dart';
import '../controller/card_editor_controller.dart';
import '../controller/card_editor_symbols_controller_ext.dart';
import '../widgets/element_adjust_panel.dart';

/// Arrow tab: arrow-glyph stickers, adjustable color and size once placed.
class ArrowTabPanel extends StatelessWidget {
  final CardEditorController controller;
  const ArrowTabPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kArrowStyles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final item = kArrowStyles[i];
              return GestureDetector(
                onTap: () => controller.addArrowSticker(item),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.iconData, size: 24, color: const Color(0xFF4A4A4A)),
                ),
              );
            },
          ),
        ),
        ElementAdjustPanel(controller: controller, showSizeSlider: true),
      ],
    );
  }
}
