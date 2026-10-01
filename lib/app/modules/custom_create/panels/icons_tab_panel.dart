import 'package:flutter/material.dart';
import '../model/symbol_asset_items.dart';
import '../controller/card_editor_controller.dart';
import '../controller/card_editor_symbols_controller_ext.dart';
import '../widgets/element_adjust_panel.dart';

/// Icons tab: general-purpose glyph stickers (website, email, phone,
/// pin...), adjustable color and size once placed.
class IconsTabPanel extends StatelessWidget {
  final CardEditorController controller;
  const IconsTabPanel({super.key, required this.controller});

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
            itemCount: kGeneralIcons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final item = kGeneralIcons[i];
              return GestureDetector(
                onTap: () => controller.addIconSticker(item),
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
