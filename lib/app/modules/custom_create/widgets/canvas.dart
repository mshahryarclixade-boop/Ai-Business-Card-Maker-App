import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../controller/card_editor_controller.dart';
import '../controller/card_editor_symbols_controller_ext.dart';
import '../model/card_element_model.dart';
import 'image_mask_clipper.dart';

class CardCanvas extends StatelessWidget {
  final CardEditorController controller;

  final GlobalKey? repaintKey;

  const CardCanvas({super.key, required this.controller, this.repaintKey});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final size = controller.orientation.value.canvasSize;

      return RepaintBoundary(
        key: repaintKey,
        child: GestureDetector(
          onTap: () => controller.selectElement(null),
          child: Container(
            width: size.width,
            height: size.height,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: controller.backgroundColor.value,
              borderRadius: BorderRadius.circular(1),
              image: controller.backgroundImage.value != null
                  ? DecorationImage(
                image: FileImage(controller.backgroundImage.value!),
                fit: BoxFit.cover,
              )
                  : controller.backgroundTemplate.value != null
                  ? DecorationImage(
                image: AssetImage(controller.backgroundTemplate.value!),
                fit: BoxFit.cover,
              )
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                for (final el in controller.elements)
                  CanvasElementWidget(controller: controller, element: el),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class CanvasElementWidget extends StatelessWidget {
  final CardEditorController controller;
  final CardElement element;

  const CanvasElementWidget({
    super.key,
    required this.controller,
    required this.element,
  });

  /// A sticker from the Social / Arrow / Icons tools (as opposed to a
  /// legacy emoji symbol, which keeps its old text-based rendering).
  bool get _isIconSticker =>
      element.type == CardElementType.symbol &&
          (element.iconData != null || element.iconAsset != null);

  static const double _pad = 20;  // room around the element for corner buttons
  static const double _hit = 32;  // tappable size of the ✕ / resize buttons

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Hidden while the canvas is being captured for saving.
      final isSelected = !controller.isCapturing.value &&
          controller.selectedElementId.value == element.id;
      final canvasSize = controller.orientation.value.canvasSize;
      final onFront = controller.currentSide.value == 0;

      return Positioned(
        left: element.position.dx - _pad,
        top: element.position.dy - _pad,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The element itself. _pad keeps its on-canvas position unchanged
            // and makes the outer Stack big enough to contain the buttons.
            Padding(
              padding: const EdgeInsets.all(_pad),
              child: GestureDetector(
                onTap: () => controller.selectElement(element.id),
                onDoubleTap: element.type == CardElementType.text
                    ? () {
                  controller.selectElement(element.id); // pehle isay select karo
                  _editTextContent(context);
                }
                    : null,
                onPanStart: (_) => controller.startDrag(element.id),
                onPanUpdate: (details) {
                  final size = _elementSize();
                  var next = element.position + details.delta;
                  next = Offset(
                    next.dx.clamp(0, (canvasSize.width - size.width).clamp(0, double.infinity)),
                    next.dy.clamp(0, (canvasSize.height - size.height).clamp(0, double.infinity)),
                  );
                  controller.updateDragPosition(element.id, next);
                },
                onPanEnd: (_) => controller.endDrag(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 1.2)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _buildContent(),
                ),
              ),
            ),

            // ✕ delete button (fully inside the Stack's bounds, so always tappable)
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.removeSelectedElement,
                  child: SizedBox(
                    width: _hit,
                    height: _hit,
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

            // Move to the other side (front <-> back)
            if (isSelected)
              Positioned(
                top: 0,
                left: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.moveSelectedToOtherSide,
                  child: SizedBox(
                    width: _hit,
                    height: _hit,
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          onFront
                              ? Icons.flip_to_back_rounded
                              : Icons.flip_to_front_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Resize handle for stickers and images
            if (isSelected &&
                (_isIconSticker || element.type == CardElementType.image))
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    final delta = (details.delta.dx + details.delta.dy) / 2;
                    if (element.type == CardElementType.image) {
                      controller.resizeSelectedImageBy(delta);
                    } else {
                      controller.resizeSelectedStickerBy(delta);
                    }
                  },
                  child: SizedBox(
                    width: _hit,
                    height: _hit,
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.open_in_full_rounded,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Size _elementSize() {
    switch (element.type) {
      case CardElementType.text:
        return Size(element.text.length * element.fontSize * 0.55 + 8,
            element.fontSize + 12);
      case CardElementType.image:
      case CardElementType.symbol:
        return Size(element.width, element.height);
    }
  }

  // Custom Fonts Here
  Widget _buildContent() {
    switch (element.type) {
      case CardElementType.text:
        if (element.text.isEmpty && controller.isCapturing.value) {
          return const SizedBox.shrink();
        }
        return Text(
          element.text.isEmpty ? 'Double tap to edit' : element.text,
          style: AppFonts.textStyle(
            element.fontFamily,
            fontSize: element.fontSize,
            fontWeight: element.fontWeight,
            color: element.color,
            fontStyle: element.italic ? FontStyle.italic : FontStyle.normal,
          ),
        );

      case CardElementType.image:
      // Bundled asset image (template logo)
        if (element.imageAsset != null) {
          return Image.asset(
            element.imageAsset!,
            width: element.width,
            height: element.height,
            fit: BoxFit.contain,
          );
        }
        if (element.imageFile == null) {
          return const SizedBox(width: 60, height: 60);
        }
        final image = Image.file(
          element.imageFile!,
          width: element.width,
          height: element.height,
          fit: BoxFit.cover,
        );
        return element.imageMask == CardImageMask.none
            ? ClipRRect(borderRadius: BorderRadius.circular(6), child: image)
            : ClipPath(clipper: ImageMaskClipper(element.imageMask), child: image);

      case CardElementType.symbol:
        if (element.iconData != null) {
          return Opacity(
            opacity: element.opacity,
            child: Icon(element.iconData, size: element.height, color: element.tintColor),
          );
        }
        if (element.iconAsset != null) {
          return Opacity(
            opacity: element.opacity,
            child: Image.asset(
              element.iconAsset!,
              width: element.width,
              height: element.height,
              color: element.tintColor,
              colorBlendMode: BlendMode.srcIn,
            ),
          );
        }
        return Text(
          element.symbol,
          style: TextStyle(fontSize: element.height * 0.75),
        );
    }
  }

  void _editTextContent(BuildContext context) {
    final textController = TextEditingController(text: element.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit text'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.beginStyleEdit();
              controller.updateSelectedText(text: textController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}