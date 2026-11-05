import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Local, non-AI background removal for company logos.
///
/// The background colour is read from the image corners and flood-filled
/// inwards from the edges only, so a colour that matches the background but is
/// enclosed by the logo (a white letter counter, a white badge) is kept.
class LogoBackgroundRemover {
  const LogoBackgroundRemover._();

  /// How far (per channel, 0-255) a pixel may differ from the background.
  static const int tolerance = 36;

  /// Logos larger than this are scaled down first: it keeps the work fast and
  /// the card never shows more detail than this.
  static const int maxSide = 1024;

  /// A PNG with the background made transparent, or null when there is no
  /// clear background (the border is not one colour, or nothing / nearly
  /// everything would be removed).
  ///
  /// The picture is decoded with Flutter's own codec (it reads everything the
  /// phone can show, HEIC and WebP included, and applies the photo's
  /// orientation); the `image` package is the fallback.
  static Future<Uint8List?> remove(Uint8List bytes) async {
    try {
      final raw = await _decodeWithFlutter(bytes);
      if (raw != null) return compute(_removeFromRaw, raw);
    } catch (_) {
      // fall through to the pure Dart decoder
    }
    return compute(removeSync, bytes);
  }

  static Future<_Raw?> _decodeWithFlutter(Uint8List bytes) async {
    var codec = await ui.instantiateImageCodec(bytes);
    var frame = await codec.getNextFrame();
    var image = frame.image;
    if (image.width > maxSide || image.height > maxSide) {
      final wide = image.width >= image.height;
      image.dispose();
      codec.dispose();
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: wide ? maxSide : null,
        targetHeight: wide ? null : maxSide,
      );
      frame = await codec.getNextFrame();
      image = frame.image;
    }
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final raw = data == null
        ? null
        : _Raw(
            image.width,
            image.height,
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
    image.dispose();
    codec.dispose();
    return raw;
  }

  static Uint8List? _removeFromRaw(_Raw raw) => _cut(
    img.Image.fromBytes(
      width: raw.width,
      height: raw.height,
      bytes: raw.rgba.buffer,
      bytesOffset: raw.rgba.offsetInBytes,
      numChannels: 4,
    ),
  );

  @visibleForTesting
  static Uint8List? removeSync(Uint8List bytes) {
    var image = img.decodeImage(bytes);
    if (image == null) return null;
    if (image.width > maxSide || image.height > maxSide) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxSide : null,
        height: image.height > image.width ? maxSide : null,
      );
    }
    return _cut(image.convert(numChannels: 4));
  }

  static Uint8List? _cut(img.Image image) {
    final w = image.width;
    final h = image.height;
    final bg = _backgroundColor(image);
    if (bg == null) return null;

    final removed = Uint8List(w * h);
    final queue = Queue<int>();

    bool isBackground(int x, int y) {
      final p = image.getPixel(x, y);
      if (p.a < 16) return true; // already transparent
      return (p.r - bg[0]).abs() <= tolerance &&
          (p.g - bg[1]).abs() <= tolerance &&
          (p.b - bg[2]).abs() <= tolerance;
    }

    void seed(int x, int y) {
      final i = y * w + x;
      if (removed[i] == 1 || !isBackground(x, y)) return;
      removed[i] = 1;
      queue.add(i);
    }

    for (var x = 0; x < w; x++) {
      seed(x, 0);
      seed(x, h - 1);
    }
    for (var y = 0; y < h; y++) {
      seed(0, y);
      seed(w - 1, y);
    }

    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      final x = i % w;
      final y = i ~/ w;
      if (x > 0) seed(x - 1, y);
      if (x < w - 1) seed(x + 1, y);
      if (y > 0) seed(x, y - 1);
      if (y < h - 1) seed(x, y + 1);
    }

    var count = 0;
    for (final r in removed) {
      count += r;
    }
    final share = count / (w * h);
    // Nothing to remove, or the "logo" is almost all background colour.
    if (share < 0.02 || share > 0.97) return null;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (removed[i] == 1) {
          image.setPixelRgba(x, y, 0, 0, 0, 0);
        } else if (_touchesRemoved(removed, w, h, x, y)) {
          // Anti-aliased edge: the more it looks like the background, the
          // more transparent it gets. Colours are never changed.
          final p = image.getPixel(x, y);
          final d = math.max(
            (p.r - bg[0]).abs(),
            math.max((p.g - bg[1]).abs(), (p.b - bg[2]).abs()),
          );
          final limit = tolerance * 3;
          if (d < limit) {
            final a = ((d - tolerance) / (limit - tolerance)).clamp(0.0, 1.0);
            image.setPixelRgba(
              x,
              y,
              p.r.toInt(),
              p.g.toInt(),
              p.b.toInt(),
              (p.a * a).round(),
            );
          }
        }
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  static bool _touchesRemoved(Uint8List r, int w, int h, int x, int y) =>
      (x > 0 && r[y * w + x - 1] == 1) ||
      (x < w - 1 && r[y * w + x + 1] == 1) ||
      (y > 0 && r[(y - 1) * w + x] == 1) ||
      (y < h - 1 && r[(y + 1) * w + x] == 1);

  /// RGB of the background, or null when the border is not mostly one
  /// colour (a photo, a gradient, a logo that fills its frame).
  ///
  /// The most common colour along the whole border wins, and at least 55 % of
  /// the border has to match it, so a logo touching an edge or a corner does
  /// not stop the removal.
  static List<int>? _backgroundColor(img.Image image) {
    final w = image.width;
    final h = image.height;
    final border = <img.Pixel>[];
    for (var x = 0; x < w; x++) {
      border.add(image.getPixel(x, 0));
      border.add(image.getPixel(x, h - 1));
    }
    for (var y = 1; y < h - 1; y++) {
      border.add(image.getPixel(0, y));
      border.add(image.getPixel(w - 1, y));
    }
    final opaque = border.where((p) => p.a >= 16).toList();
    // Already cut out (a transparent border): nothing to remove.
    if (opaque.length < border.length * 0.2) return null;

    // Most common colour in 16-level buckets.
    final buckets = <int, List<img.Pixel>>{};
    for (final p in opaque) {
      final key =
          ((p.r.toInt() >> 4) << 8) |
          ((p.g.toInt() >> 4) << 4) |
          (p.b.toInt() >> 4);
      (buckets[key] ??= []).add(p);
    }
    final top = buckets.values.reduce((a, b) => a.length >= b.length ? a : b);
    var r = 0, g = 0, b = 0;
    for (final p in top) {
      r += p.r.toInt();
      g += p.g.toInt();
      b += p.b.toInt();
    }
    final ref = [r ~/ top.length, g ~/ top.length, b ~/ top.length];

    final matching = border.where(
      (p) =>
          p.a < 16 ||
          ((p.r - ref[0]).abs() <= tolerance &&
              (p.g - ref[1]).abs() <= tolerance &&
              (p.b - ref[2]).abs() <= tolerance),
    );
    if (matching.length < border.length * 0.55) return null;
    return ref;
  }
}

/// Decoded pixels handed to the isolate.
class _Raw {
  const _Raw(this.width, this.height, this.rgba);

  final int width;
  final int height;
  final Uint8List rgba;
}
