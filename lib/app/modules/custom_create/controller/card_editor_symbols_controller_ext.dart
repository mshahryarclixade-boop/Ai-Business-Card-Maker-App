import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';

import 'card_editor_controller.dart';
import '../model/card_element_model.dart';
import '../model/symbol_asset_items.dart';
import '../../../core/services/recent_designs_service.dart';

extension CardEditorSymbolsX on CardEditorController {
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Offset _centerSpawn(double size) {
    final canvas = orientation.value.canvasSize;
    return Offset((canvas.width - size) / 2, (canvas.height - size) / 2);
  }

  CardElement? get _selected {
    final id = selectedElementId.value;
    if (id == null) return null;
    return elements.firstWhereOrNull((e) => e.id == id);
  }

  void _updateSelected(CardElement Function(CardElement) update) {
    final id = selectedElementId.value;
    if (id == null) return;
    final idx = elements.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    elements[idx] = update(elements[idx]);
  }

  // --------------------------------------------------------------- Stickers
  /// Material icon ya Font Awesome icon dono ko plain IconData mein badalta hai.
  IconData? _toIconData(IconAssetItem item) =>
      item.iconData ?? item.faIconData?.data;

  void _addSticker(IconAssetItem item, double size) {
    final icon = _toIconData(item);
    if (icon == null) return;
    // Adding a sticker is an Undo step like adding text or a symbol: without
    // it the first sticker (and every one added in a row) could not be undone.
    recordHistory();
    final el = CardElement.sticker(
      id: _newId(),
      position: _centerSpawn(size),
      iconData: icon,
      width: size,
      height: size,
    );
    elements.add(el);
    selectElement(el.id);
  }

  // ---------------------------------------------------------------- Social
  void addSocialSticker(IconAssetItem item) => _addSticker(item, 40);

  // ----------------------------------------------------------------- Arrow
  void addArrowSticker(IconAssetItem item) => _addSticker(item, 36);

  // ----------------------------------------------------------------- Icons
  void addIconSticker(IconAssetItem item) => _addSticker(item, 32);

  // ----------------------------------------------- shared color / opacity / size
  void setSelectedTint(Color color) =>
      _updateSelected((e) => e.copyWith(tintColor: color));

  void setSelectedOpacity(double opacity) =>
      _updateSelected((e) => e.copyWith(opacity: opacity.clamp(0.1, 1.0)));

  void setSelectedStickerSize(double size) {
    final clamped = size.clamp(16.0, 140.0);
    _updateSelected((e) => e.copyWith(width: clamped, height: clamped));
  }

  void resizeSelectedStickerBy(double delta) {
    final current = _selected;
    if (current == null) return;
    setSelectedStickerSize(current.height + delta);
  }

  // ---------------------------------------------------------------- Shapes
  void applyImageMask(CardImageMask mask) {
    final selectedId = selectedElementId.value;
    final selectedImage = selectedId != null
        ? elements.firstWhereOrNull(
            (e) => e.id == selectedId && e.type == CardElementType.image)
        : null;
    final target = selectedImage ??
        elements.lastWhereOrNull((e) => e.type == CardElementType.image);
    if (target == null) return;
    final idx = elements.indexWhere((e) => e.id == target.id);
    elements[idx] = target.copyWith(imageMask: mask);
  }

  // ---------------------------------------------------- Save to Recent Designs
  Map<String, dynamic> _buildDesignData() {
    return {
      'orientation': orientation.value.name,
      'backgroundColor': backgroundColor.value.toARGB32(),
      'backgroundImagePath': backgroundImage.value?.path,
      'backgroundTemplate': backgroundTemplate.value,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }

  // ---------------------------------------------------- Save to Recent Designs
  /// Makes sure the images on the current side are decoded, otherwise the
  /// first frame after a side switch could be captured without them.
  Future<void> _precacheCurrentSide() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final providers = <ImageProvider>[
      if (backgroundImage.value != null) FileImage(backgroundImage.value!),
      if (backgroundTemplate.value != null)
        AssetImage(backgroundTemplate.value!),
      for (final e in elements)
        if (e.imageFile != null) FileImage(e.imageFile!),
      for (final e in elements)
        if (e.iconAsset != null) AssetImage(e.iconAsset!),
    ];
    for (final p in providers) {
      try {
        await precacheImage(p, ctx);
      } catch (_) {}
    }
  }

  /// Captures the side on screen (or switches to [side] first).
  Future<Uint8List?> _captureCurrent(GlobalKey repaintKey) async {
    await _precacheCurrentSide();
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> saveToRecentDesigns(GlobalKey repaintKey) async {
    // Hide editor-only UI (border, ✕, handles) before capturing.
    isCapturing.value = true;
    final startSide = currentSide.value;
    final otherSide = 1 - startSide;
    try {
      ensureBackInitialized();

      // 1. The side on screen is captured where it is, and that picture is
      //    laid over the canvas...
      final shown = await _captureCurrent(repaintKey);
      if (shown == null) return;
      final ctx = Get.context;
      if (ctx != null) {
        try {
          await precacheImage(MemoryImage(shown), ctx);
        } catch (_) {}
      }
      captureFreeze.value = shown;
      await WidgetsBinding.instance.endOfFrame;

      // 2. ...so the other side can be switched in and captured behind it
      //    without ever being seen.
      switchToSide(otherSide);
      final hidden = await _captureCurrent(repaintKey);
      if (hidden == null) return;

      await Get.find<RecentDesignsService>().save(
        startSide == 0 ? shown : hidden,
        backThumbnailBytes: startSide == 0 ? hidden : shown,
        designData: buildDesignData(),
      );
    } finally {
      if (currentSide.value != startSide) switchToSide(startSide);
      // Let the original side draw once before the cover comes off.
      await WidgetsBinding.instance.endOfFrame;
      captureFreeze.value = null;
      isCapturing.value = false;
    }
  }
}
