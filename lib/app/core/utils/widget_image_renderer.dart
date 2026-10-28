import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Renders a widget to a PNG without putting it on screen — e.g. a card's
/// thumbnail for My Cards.
///
/// Images are only drawn if they are already decoded, so pass every image
/// the widget shows as [images]; they are loaded first. Fonts must also be
/// loaded beforehand (e.g. `GoogleFonts.pendingFonts()`).
abstract final class WidgetImageRenderer {
  static Future<Uint8List> render(
    Widget widget, {
    required Size size,
    double pixelRatio = 3,
    List<ImageProvider> images = const [],
  }) async {
    await Future.wait(images.map(_load));

    final boundary = RenderRepaintBoundary();
    final view =
        ui.PlatformDispatcher.instance.implicitView ??
        ui.PlatformDispatcher.instance.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(child: boundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: 1,
      ),
    );
    final pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.fromSize(size: size, child: widget),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    // Twice: images already in the cache resolve during the first build
    // and mark their widgets dirty for the second.
    for (var i = 0; i < 2; i++) {
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
      pipeline
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
    }

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  /// Decodes [provider] into the image cache (failures are ignored: the
  /// image is then simply missing from the render).
  static Future<void> _load(ImageProvider provider) {
    final done = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
      onError: (_, _) {
        if (!done.isCompleted) done.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return done.future;
  }
}
