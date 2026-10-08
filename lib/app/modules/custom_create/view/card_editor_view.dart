import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/side_switcher.dart';
import '../../template/model/template_item.dart';
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
  final TemplateItem? template;
  final File? qrToAdd;

  const CardEditorView({
    super.key,
    this.design,
    this.template,
    this.qrToAdd,
  });

  @override
  State<CardEditorView> createState() => _CardEditorViewState();
}

class _CardEditorViewState extends State<CardEditorView> {
  late final CardEditorController controller;

  String _emptyBgPath(String previewPath) => previewPath.replaceFirst(
    'assets/images/templates/',
    'assets/images/empty_templates/',
  );

  String _templateJsonPath(TemplateItem t) => t.frontImagePath
      .replaceFirst('assets/images/templates/', 'assets/template_json/')
      .replaceFirst('_front.png', '.json');

  /// Adds the generated QR after the design/template has finished loading,
  /// so nothing can reset the canvas after the QR is placed.
  void _scheduleQrAdd() {
    final qr = widget.qrToAdd;
    if (qr == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        debugPrint('QR add: file=${qr.path}, exists=${qr.existsSync()}');
        await controller.addGeneratedQrToCanvas(qr);
        debugPrint('QR added: elements=${controller.elements.length}');
      } catch (e, st) {
        debugPrint('QR add FAILED: $e\n$st');
      }
    });
  }

  @override
  void initState() {
    super.initState();

    final template = widget.template;

    // Create a fresh controller for this editor screen.
    controller = Get.put(
      CardEditorController(
        initialOrientation: template?.orientation == TemplateOrientation.vertical
            ? CardOrientation.portrait
            : CardOrientation.landscape,
      ),
    );

    if (template != null) {
      controller.loadFromTemplateAssets(
        frontAsset: _emptyBgPath(template.frontImagePath),
        backAsset: _emptyBgPath(template.backImagePath),
        orientation: template.orientation == TemplateOrientation.vertical
            ? CardOrientation.portrait
            : CardOrientation.landscape,
      );

      // TEMP: put the template logo on both sides so we can position it.
      // final logoPath = template.frontImagePath
      //     .replaceFirst('assets/images/templates/', 'assets/images/template_logos/')
      //     .replaceFirst('_front.png', '_logo.png');
      // controller.addAssetImage(logoPath);
      // controller.switchToSide(1);
      // controller.addAssetImage(logoPath);
      // controller.switchToSide(0);
      controller.loadFromTemplateJson(_templateJsonPath(template));

      _scheduleQrAdd();
      return;
    }

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

    _scheduleQrAdd();
  }

  @override
  void dispose() {
    Get.delete<CardEditorController>();
    super.dispose();
  }

  /// DEV ONLY: prints the template JSON in the console and copies it.
  Future<void> _exportTemplateJson() async {
    // Works for both: opened from "Edit Template" and from a saved design.
    final templateId = widget.template?.id ?? 'travel_01';

    controller.selectElement(null);
    final json = controller.buildTemplateJson(templateId);

    debugPrint('===== TEMPLATE JSON START =====');
    debugPrint(json);
    debugPrint('===== TEMPLATE JSON END =====');

    await Clipboard.setData(ClipboardData(text: json));

    Get.snackbar(
      'JSON exported',
      'Copied to clipboard and printed in the console.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
  }

  /// DEV ONLY: type an exact font size.
  void _typeFontSize(double current) {
    final textController =
    TextEditingController(text: current.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Font size'),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(textController.text.trim());
              if (v != null) controller.setSelectedFontSize(v);
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _devStepButton(IconData icon, double step) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.nudgeSelectedFontSize(step),
      // long press = half step, for fine tuning
      onLongPress: () => controller.nudgeSelectedFontSize(step / 2),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }

  /// DEV ONLY: "-  18.0  +" bar, visible when a text element is selected.
  Widget _devSizeBar() {
    return Obx(() {
      final el = controller.selectedElement;
      if (el == null || el.type != CardElementType.text) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _devStepButton(Icons.remove, -1),
            GestureDetector(
              onTap: () => _typeFontSize(el.fontSize),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  el.fontSize.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _devStepButton(Icons.add, 1),
          ],
        ),
      );
    });
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

            // DEV ONLY: shows only in debug builds, and only for templates.
            if (false && kDebugMode)
              Positioned(
                top: 70,
                left: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _exportTemplateJson,
                      icon: const Icon(Icons.data_object, size: 16),
                      label: const Text('JSON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _devSizeBar(),
                  ],
                ),
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