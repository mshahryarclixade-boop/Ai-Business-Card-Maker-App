import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/side_switcher.dart';
import '../controller/card_editor_controller.dart';
import '../controller/card_editor_symbols_controller_ext.dart';
import '../model/card_element_model.dart';
import '../panels/background_tool_panel.dart';
import '../panels/image_tool_panel.dart';
import '../panels/qr_tool_panel.dart';
import '../panels/symbols_tool_panel.dart';
import '../panels/text_tool_panel.dart';
import '../widgets/bottom_toolbar.dart';
import '../widgets/canvas.dart';
import '../widgets/custom_color_picker_popup.dart';
import '../widgets/top_bar.dart';

class CardEditorView extends StatefulWidget {
  final RecentDesign? design;

  const CardEditorView({
    super.key,
    this.design,
  });

  @override
  State<CardEditorView> createState() => _CardEditorViewState();
}

class _CardEditorViewState extends State<CardEditorView> {
  late final CardEditorController controller;

  @override
  void initState() {
    super.initState();

    // Create a fresh controller for this editor screen.
    controller = Get.put(CardEditorController());

    final design = widget.design;
    if (design != null) {
      if (design.designData != null) {
        // Normal saved design: full structured elements for both sides.
        controller.loadFromDesign(design);
      } else {
        // AI-generated card (or a legacy thumbnail-only design): only
        // rendered images exist, so load front and back as backgrounds.
        controller.loadFromImage(
          design.file,
          backImageFile: design.backFile,
        );
      }
    }
  }

  @override
  void dispose() {
    Get.delete<CardEditorController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey canvasRepaintKey = GlobalKey();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                TopBar(
                  controller: controller,
                  repaintKey: canvasRepaintKey,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Obx(() {
                          final size =
                              controller.orientation.value.canvasSize;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: size.width,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: SideSwitcher(controller: controller),
                                ),
                              ),
                              const SizedBox(height: 6),
                              CardCanvas(
                                controller: controller,
                                repaintKey: canvasRepaintKey,
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                Obx(() {
                  switch (controller.activeTool.value) {
                    case CardTool.text:
                      return TextToolPanel(controller: controller);
                    case CardTool.qr:
                      return QrToolPanel(controller: controller);
                    case CardTool.background:
                      return BackgroundToolPanel(controller: controller);
                    case CardTool.image:
                      return ImageToolPanel(controller: controller);
                    case CardTool.symbols:
                      return SymbolsToolPanel(controller: controller);
                    default:
                      return const SizedBox.shrink();
                  }
                }),
                BottomToolbar(controller: controller),
              ],
            ),

            Obx(() {
              final target = controller.colorPickerTarget.value;

              if (target == null) {
                return const SizedBox.shrink();
              }

              final isBackground = target == ColorPickerTarget.background;
              final isElement = target == ColorPickerTarget.element;

              return Positioned(
                top: 76,
                right: 16,
                child: CustomColorPickerPopup(
                  initialColor: isBackground
                      ? controller.backgroundColor.value
                      : isElement
                      ? (controller.selectedElement?.tintColor ?? Colors.black)
                      : (controller.selectedElement?.color ?? Colors.black),
                  onColorChanged: (c) {
                    if (isBackground) {
                      controller.setBackgroundColor(c);
                    } else if (isElement) {
                      controller.setSelectedTint(c);
                    } else {
                      controller.beginStyleEdit();
                      controller.updateSelectedText(color: c);
                    }
                  },
                  savedColors: isBackground
                      ? controller.savedBackgroundColors
                      : controller.savedTextColors,
                  onAddSavedColor: isBackground
                      ? controller.addSavedBackgroundColor
                      : controller.addSavedTextColor,
                  onClose: controller.closeColorPicker,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}