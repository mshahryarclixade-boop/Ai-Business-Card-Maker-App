import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/card_editor_controller.dart';
import '../../../core/translations/tr_extension.dart';

/// Bottom toolbar: Text, QR code, Background, Image, Symbols, Logo.
class BottomToolbar extends StatelessWidget {
  final CardEditorController controller;
  const BottomToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDF2))),
      ),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Side padding so the first and last highlight is never cut by the
          // screen edge.
          padding: const EdgeInsets.symmetric(horizontal: ToolbarIcon.edge),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width - 2 * ToolbarIcon.edge,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ToolbarIcon(
                  asset: 'assets/icons/text.png',
                  label: 'custom_create_toolbar_text'.tr,
                  active: controller.activeTool.value == CardTool.text,
                  onTap: () => controller.selectTool(CardTool.text),
                ),
                ToolbarIcon(
                  asset: 'assets/icons/qrcode.png',
                  label: 'custom_create_toolbar_qr_code'.tr,
                  active: controller.activeTool.value == CardTool.qr,
                  onTap: () => controller.selectTool(CardTool.qr),
                ),
                ToolbarIcon(
                  asset: 'assets/icons/background.png',
                  label: 'custom_create_toolbar_background'.tr,
                  active: controller.activeTool.value == CardTool.background,
                  onTap: () => controller.selectTool(CardTool.background),
                ),
                ToolbarIcon(
                  asset: 'assets/icons/image.png',
                  label: 'custom_create_toolbar_image'.tr,
                  active: controller.activeTool.value == CardTool.image,
                  onTap: () => controller.selectTool(CardTool.image),
                ),
                ToolbarIcon(
                  asset: 'assets/icons/symbol.png',
                  label: 'custom_create_toolbar_symbols'.tr,
                  active: controller.activeTool.value == CardTool.symbols,
                  onTap: () => controller.selectTool(CardTool.symbols),
                ),
                ToolbarIcon(
                  icon: Icons.workspace_premium_outlined,
                  label: 'custom_create_toolbar_logo'.tr,
                  active: controller.activeTool.value == CardTool.logo,
                  onTap: () => controller.selectTool(CardTool.logo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ToolbarIcon extends StatelessWidget {
  final String? asset;
  final IconData? icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const ToolbarIcon({
    super.key,
    this.asset,
    this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  /// Side padding of the row, and the gap kept between two neighbours.
  static const double edge = 12;
  static const double gap = 8;
  static const double maxWidth = 96;

  /// Width of one item: four fit on the screen before scrolling (so each has
  /// room), capped on wide screens.
  static double itemWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 2 * edge;
    return (w / 4).clamp(0.0, maxWidth);
  }

  static const Color _activeColor = Color(0xFF444494);
  static const Color _activeBg = Color(0xFFCACAEF);

  @override
  Widget build(BuildContext context) {
    final color = active ? _activeColor : const Color(0xFF6B6B72);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Four items fill the screen width; the rest scroll.
        width: itemWidth(context) - gap,
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: gap / 2),
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
            if (asset != null)
              Image.asset(
                asset!,
                width: 21,
                height: 21,
                color: color, // remove if the PNGs have their own colors
              )
            else
              Icon(icon, size: 24, color: color),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
