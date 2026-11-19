import 'package:flutter/material.dart';
import '../controller/card_editor_controller.dart';
import '../controller/card_editor_symbols_controller_ext.dart';
import '../model/symbol_asset_items.dart';
import '../widgets/element_adjust_panel.dart';
import '../widgets/panel_shared.dart';

/// Every symbol in one list, no filters: social first, then icons, then
/// arrows (6 of each).
class SymbolsToolPanel extends StatelessWidget {
  final CardEditorController controller;
  const SymbolsToolPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = <(IconAssetItem, void Function(IconAssetItem))>[
      for (final i in kSocialIcons) (i, controller.addSocialSticker),
      for (final i in kGeneralIcons) (i, controller.addIconSticker),
      for (final i in kArrowStyles) (i, controller.addArrowSticker),
    ];
    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelHeader(title: '', onBack: controller.closeToolPanel),
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final (item, add) = items[i];
                return GestureDetector(
                  onTap: () => add(item),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: item.buildIcon(
                      size: 24,
                      color: const Color(0xFF4A4A4A),
                    ),
                  ),
                );
              },
            ),
          ),
          ElementAdjustPanel(controller: controller, showSizeSlider: true),
        ],
      ),
    );
  }
}
