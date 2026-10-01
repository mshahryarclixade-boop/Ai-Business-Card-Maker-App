import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/card_editor_controller.dart';
import '../model/card_element_model.dart';
import '../widgets/color_palette.dart';
import '../widgets/panel_shared.dart';

/// Text tool: Add Text / Edit Text, then the font/size/color style bar.
class TextToolPanel extends StatelessWidget {
  final CardEditorController controller;

  const TextToolPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.textStyleBarOpen.value) {
        return TextStyleBar(controller: controller);
      }

      return PanelContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back icon only — no "Text" title.
            PanelHeader(
              title: '',
              onBack: controller.closeToolPanel,
            ),

            const SizedBox(height: 14),

            // Both text options are centered.
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextToolOption(
                    icon: Icons.text_fields_rounded,
                    label: 'Add Text',
                    onTap: controller.addText,
                  ),
                  const SizedBox(width: 20),
                  TextToolOption(
                    icon: Icons.edit_note_rounded,
                    label: 'Edit Text',
                    onTap: controller.openTextStyleBar,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class TextToolOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const TextToolOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // Both Add Text and Edit Text now have the same background.
          color: const Color(0xFFF3F3FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.text_fields_rounded,
              size: 20,
              color: Color(0xFF6B6B72),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B6B72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextStyleBar extends StatelessWidget {
  final CardEditorController controller;

  const TextStyleBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expanded = controller.expandedStylePanel.value;
      final el = controller.selectedElement;

      return PanelContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PanelHeader(
              title: 'Edit Text',
              onBack: controller.closeTextStyleBar,
            ),
            const SizedBox(height: 10),

            if (expanded == 'font')
              FontListPanel(
                controller: controller,
                current: el?.fontFamily,
              ),

            if (expanded == 'size')
              SizeListPanel(
                controller: controller,
                current: el?.fontSize,
              ),

            // Use the SAME color palette used by the Background tool.
            // The rainbow tile opens the same custom color picker flow.
            if (expanded == 'color')
              ColorPaletteGrid(
                selected: el?.color,
                swatchSize: 30,
                spacing: 14,
                onSelect: (color) {
                  controller.beginStyleEdit();
                  controller.updateSelectedText(color: color);
                },
                onOpenCustomPicker: () => controller.openColorPicker(
                  target: ColorPickerTarget.text,
                ),
              ),

            if (expanded.isNotEmpty)
              const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: StyleSegment(
                    label: el?.fontFamily ?? 'SF Pro',
                    active: expanded == 'font',
                    onTap: () =>
                        controller.toggleStylePanel('font'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StyleSegment(
                    label:
                    '${(el?.fontSize ?? 16).toStringAsFixed(0)}pt',
                    active: expanded == 'size',
                    onTap: () =>
                        controller.toggleStylePanel('size'),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      controller.toggleStylePanel('color'),
                  child: Container(
                    height: 38,
                    width: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F8),
                      borderRadius: BorderRadius.circular(10),
                      border: expanded == 'color'
                          ? Border.all(
                        color: AppColors.primary,
                      )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: el?.color ?? Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class StyleSegment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const StyleSegment({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(color: AppColors.primary)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11.5,
                  color: Color(0xFF1E1E24),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF9A9AA2),
            ),
          ],
        ),
      ),
    );
  }
}

class FontListPanel extends StatelessWidget {
  final CardEditorController controller;
  final String? current;

  const FontListPanel({
    super.key,
    required this.controller,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: kSampleFontFamilies.length,
        itemBuilder: (_, i) {
          final font = kSampleFontFamilies[i];
          final selected = font == current;

          // font texts
          return ListTile(
            dense: true,
            title: Text(
              font,
              // 🔴 yahi change hai — har naam apne hi font mein render hoga
              style: AppFonts.textStyle(
                font,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.primary : const Color(0xFF1E1E24),
              ),
            ),
            trailing: selected
                ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.primary,
            )
                : null,
            onTap: () {
              controller.beginStyleEdit();
              controller.updateSelectedText(fontFamily: font);
            },
          );
        },
      ),
    );
  }
}

class SizeListPanel extends StatelessWidget {
  final CardEditorController controller;
  final double? current;

  const SizeListPanel({
    super.key,
    required this.controller,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: kSampleFontSizes.length,
        itemBuilder: (_, i) {
          final size = kSampleFontSizes[i];
          final selected = size == current;

          return ListTile(
            dense: true,
            title: Text(
              '${size.toStringAsFixed(0)}pt',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? AppColors.primary
                    : const Color(0xFF1E1E24),
              ),
            ),
            trailing: selected
                ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.primary,
            )
                : null,
            onTap: () {
              controller.beginStyleEdit();
              controller.updateSelectedText(fontSize: size);
            },
          );
        },
      ),
    );
  }
}