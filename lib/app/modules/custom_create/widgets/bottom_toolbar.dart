import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/card_editor_controller.dart';

/// Bottom toolbar: Text, QR code, Background, Image, Symbols.
class BottomToolbar extends StatelessWidget {
  final CardEditorController controller;
  const BottomToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDF2))),
      ),
      child: Obx(
            () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ToolbarIcon(
              asset: 'assets/icons/text.png',
              label: 'Text',
              active: controller.activeTool.value == CardTool.text,
              onTap: () => controller.selectTool(CardTool.text),
            ),
            ToolbarIcon(
              asset: 'assets/icons/qrcode.png',
              label: 'QR code',
              active: controller.activeTool.value == CardTool.qr,
              onTap: () => controller.selectTool(CardTool.qr),
            ),
            ToolbarIcon(
              asset: 'assets/icons/background.png',
              label: 'Background',
              active: controller.activeTool.value == CardTool.background,
              onTap: () => controller.selectTool(CardTool.background),
            ),
            ToolbarIcon(
              asset: 'assets/icons/image.png',
              label: 'Image',
              active: controller.activeTool.value == CardTool.image,
              onTap: () => controller.selectTool(CardTool.image),
            ),
            ToolbarIcon(
              asset: 'assets/icons/symbol.png',
              label: 'Symbols',
              active: controller.activeTool.value == CardTool.symbols,
              onTap: () => controller.selectTool(CardTool.symbols),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolbarIcon extends StatelessWidget {
  final String asset;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const ToolbarIcon({
    super.key,
    required this.asset,
    required this.label,
    required this.active,
    required this.onTap,
  });

  static const Color _activeColor = Color(0xFF444494);
  static const Color _activeBg = Color(0xFFCACAEF);

  @override
  Widget build(BuildContext context) {
    final color = active ? _activeColor : const Color(0xFF6B6B72);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 70,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          // border: Border.all(
          //   color: active ? _activeColor : Colors.transparent,
          //   width: 1,
          // ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: 21,
              height: 21,
              color: color, // remove if the PNGs have their own colors
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}