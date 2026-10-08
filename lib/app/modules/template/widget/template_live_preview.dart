import 'package:flutter/material.dart';

import '../../../core/utils/app_fonts.dart';
import '../../custom_create/model/card_element_model.dart';
import '../model/template_live_data.dart';

class TemplateCardCanvas extends StatelessWidget {
  final TemplateSideData side;
  final CardOrientation orientation;
  final GlobalKey? repaintKey;

  const TemplateCardCanvas({
    super.key,
    required this.side,
    required this.orientation,
    this.repaintKey,
  });

  static const double _pad = 4;

  @override
  Widget build(BuildContext context) {
    final size = orientation.canvasSize;

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: size.width,
        height: size.height,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage(side.background),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            for (final el in side.elements)
              Positioned(
                left: el.position.dx + _pad,
                top: el.position.dy + _pad,
                child: _content(el),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(CardElement el) {
    switch (el.type) {
      case CardElementType.text:
        return Text(
          el.text,
          style: AppFonts.textStyle(
            el.fontFamily,
            fontSize: el.fontSize,
            fontWeight: el.fontWeight,
            color: el.color,
            fontStyle: el.italic ? FontStyle.italic : FontStyle.normal,
          ),
        );

      case CardElementType.image:
        if (el.imageAsset != null) {
          return Image.asset(
            el.imageAsset!,
            width: el.width,
            height: el.height,
            fit: BoxFit.contain,
          );
        }
        if (el.imageFile == null) {
          return const SizedBox(width: 60, height: 60);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            el.imageFile!,
            width: el.width,
            height: el.height,
            fit: BoxFit.cover,
          ),
        );

      case CardElementType.symbol:
        if (el.iconData != null) {
          return Opacity(
            opacity: el.opacity,
            child: Icon(el.iconData, size: el.height, color: el.tintColor),
          );
        }
        if (el.iconAsset != null) {
          return Opacity(
            opacity: el.opacity,
            child: Image.asset(
              el.iconAsset!,
              width: el.width,
              height: el.height,
              color: el.tintColor,
              colorBlendMode: BlendMode.srcIn,
            ),
          );
        }
        return Text(el.symbol, style: TextStyle(fontSize: el.height * 0.75));
    }
  }
}

/// Fills whatever space it is given (cover), like the card image on Home.
class TemplateLivePreview extends StatelessWidget {
  final TemplateSideData side;
  final CardOrientation orientation;
  final GlobalKey? repaintKey;

  const TemplateLivePreview({
    super.key,
    required this.side,
    required this.orientation,
    this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: TemplateCardCanvas(
          side: side,
          orientation: orientation,
          repaintKey: repaintKey,
        ),
      ),
    );
  }
}