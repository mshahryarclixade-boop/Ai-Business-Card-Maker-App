import '../../../core/widgets/tap_target.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart' hide Trans;
import '../../../core/utils/app_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../controller/card_editor_controller.dart';
import '../controller/card_editor_symbols_controller_ext.dart';
import '../model/card_element_model.dart';
import 'card_shape.dart';
import 'edit_text_dialog.dart';
import 'image_mask_clipper.dart';
import '../../../core/translations/tr_extension.dart';

/// The card plus a working margin around it ([margin] on every side).
///
/// Elements can be moved and resized anywhere in that margin, outside the
/// card, while editing. Only the card itself is the final picture: what lies
/// outside it is cut away when the card is saved (see `_captureCurrent`) and
/// when it is drawn anywhere else.
///
/// The margin is part of this widget's size (not just painted beyond it) so
/// that touches there still reach the elements.
class CardCanvas extends StatelessWidget {
  final CardEditorController controller;

  /// The boundary of the whole working area (card + margin). Crop its picture
  /// with [cardRectIn] to get the card.
  final GlobalKey? repaintKey;

  const CardCanvas({super.key, required this.controller, this.repaintKey});

  /// Room around the card, in card units.
  static const double margin = 140;

  /// Where the card is inside a picture of the working area taken with
  /// [pixelRatio].
  static Rect cardRectIn(Size card, double pixelRatio) => Rect.fromLTWH(
    margin * pixelRatio,
    margin * pixelRatio,
    card.width * pixelRatio,
    card.height * pixelRatio,
  );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final size = controller.orientation.value.canvasSize;

      return Directionality(
        textDirection: TextDirection.ltr, // cards always render left-to-right
        // The overlays (frozen picture, outside mask) are NOT inside the
        // RepaintBoundary: they must never end up in the saved picture.
        child: SizedBox(
          width: size.width + margin * 2,
          height: size.height + margin * 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  key: repaintKey,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Tapping anywhere that is not an element, card or not.
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.selectElement(null),
                        ),
                      ),
                      Positioned(left: margin, top: margin, child: _card(size)),
                      for (final el in controller.elements)
                        CanvasElementWidget(
                          controller: controller,
                          element: el,
                        ),
                    ],
                  ),
                ),
              ),
              // While saving, the picture of the card as it was: the other
              // side is switched in and captured underneath it.
              if (controller.captureFreeze.value != null)
                Positioned(
                  left: margin,
                  top: margin,
                  width: size.width,
                  height: size.height,
                  child: IgnorePointer(
                    child: Image.memory(
                      controller.captureFreeze.value!,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              // While saving, hide everything outside the card so the other
              // side's outside-card elements are never seen. This is cropped
              // away from the saved picture anyway.
              if (controller.isCapturing.value)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _OutsideCardMask(
                        Rect.fromLTWH(margin, margin, size.width, size.height),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// The card's own background (no elements: they live in the working area).
  Widget _card(Size size) {
    return IgnorePointer(
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
      ),
    );
  }
}

/// Paints the editor background everywhere except the card.
class _OutsideCardMask extends CustomPainter {
  _OutsideCardMask(this.card);

  final Rect card;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(card);
    canvas.drawPath(path, Paint()..color = AppColors.scaffoldBg);
  }

  @override
  bool shouldRepaint(_OutsideCardMask old) => old.card != card;
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

  static const double _pad = 20; // room around the element for corner buttons
  static const double _hit = 32; // tappable size of the ✕ / resize buttons

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Hidden while the canvas is being captured for saving.
      final isSelected =
          !controller.isCapturing.value &&
          controller.selectedElementId.value == element.id;
      final canvasSize = controller.orientation.value.canvasSize;
      final onFront = controller.currentSide.value == 0;

      return Positioned(
        left: CardCanvas.margin + element.position.dx - _pad,
        top: CardCanvas.margin + element.position.dy - _pad,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The element itself. _pad keeps its on-canvas position unchanged
            // and makes the outer Stack big enough to contain the buttons.
            Padding(
              padding: const EdgeInsets.all(_pad),
              child: GestureDetector(
                onTap: () => element.type == CardElementType.text
                    ? controller.selectAndEditText(element.id)
                    : controller.selectElement(element.id),
                onDoubleTap: element.type == CardElementType.text
                    ? () {
                        controller.selectElement(
                          element.id,
                        ); // pehle isay select karo
                        _editTextContent(context);
                      }
                    : null,
                onPanStart: (_) => controller.startDrag(element.id),
                onPanUpdate: (details) {
                  // Free to leave the card: only the working area around it
                  // ends the drag, so the element can always be grabbed again.
                  final size = _elementSize();
                  const m = CardCanvas.margin;
                  // [details.delta] is already in card units: the card is drawn
                  // inside the scaled (fit-to-screen) transform.
                  final next = element.position + details.delta;
                  controller.updateDragPosition(
                    element.id,
                    Offset(
                      next.dx.clamp(
                        -m,
                        math.max(-m, canvasSize.width + m - size.width),
                      ),
                      next.dy.clamp(
                        -m,
                        math.max(-m, canvasSize.height + m - size.height),
                      ),
                    ),
                  );
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
                child: TapTarget(
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
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
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
                child: TapTarget(
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
              ),

            // Resize handle for stickers and images
            if (isSelected &&
                (_isIconSticker ||
                    element.type == CardElementType.image ||
                    element.type == CardElementType.shape))
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // One resize gesture = one Undo step.
                  onPanStart: (_) => controller.startDrag(element.id),
                  onPanEnd: (_) => controller.endDrag(),
                  onPanUpdate: (details) {
                    final d = details.delta; // card units (see above)
                    if (element.type == CardElementType.shape) {
                      // A shape is resized freely, width and height apart.
                      controller.resizeSelectedShapeBy(d.dx, d.dy);
                      return;
                    }
                    final delta = (d.dx + d.dy) / 2;
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
                        child: const Icon(
                          Icons.open_in_full_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
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
        return Size(
          element.text.length * element.fontSize * 0.55 + 8,
          element.fontSize + 12,
        );
      case CardElementType.image:
      case CardElementType.symbol:
      case CardElementType.shape:
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
          element.text.isEmpty
              ? 'custom_create_double_tap_to_edit'.tr
              : element.text,
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
            : ClipPath(
                clipper: ImageMaskClipper(element.imageMask),
                child: image,
              );

      case CardElementType.shape:
        return CardShapeView(element: element);

      case CardElementType.symbol:
        if (element.iconData != null) {
          return Opacity(
            opacity: element.opacity,
            child: Icon(
              element.iconData,
              size: element.height,
              color: element.tintColor,
            ),
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

  Future<void> _editTextContent(BuildContext context) async {
    final text = await showEditTextDialog(context, element.text);
    if (text == null) return; // cancelled
    controller.beginStyleEdit();
    controller.updateSelectedText(text: text);
  }
}
