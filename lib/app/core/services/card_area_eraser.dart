import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// An area to wipe. x, y, h (and w when given) are fractions of the image.
/// Without w, the width is h * image height * widthFactor.
class EraseBox {
  const EraseBox(this.x, this.y, this.h, {this.w, this.widthFactor = 1});

  final double x;
  final double y;
  final double h;
  final double? w;
  final double widthFactor;
}

/// Wipes areas of a card image locally (no API call): each row inside the
/// box is filled with a blend of the colors just left and right of it.
class CardAreaEraser {
  CardAreaEraser._();

  static Future<Uint8List> erase(Uint8List png, List<EraseBox> boxes) async {
    if (boxes.isEmpty) return png;

    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final img = frame.image;
    final w = img.width;
    final h = img.height;
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    if (data == null) return png;
    final px = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    const pad = 6;
    for (final b in boxes) {
      final hp = b.h * h;
      final wp = b.w != null ? b.w! * w : hp * b.widthFactor;

      final left = (b.x * w - pad).floor().clamp(0, w - 1).toInt();
      final top = (b.y * h - pad).floor().clamp(0, h - 1).toInt();
      final right = (b.x * w + wp + pad).ceil().clamp(0, w - 1).toInt();
      final bottom = (b.y * h + hp + pad).ceil().clamp(0, h - 1).toInt();
      if (right <= left || bottom <= top) continue;

      final lx = (left - 5).clamp(0, w - 1).toInt();
      final rx = (right + 5).clamp(0, w - 1).toInt();

      for (var y = top; y <= bottom; y++) {
        final l = _avg(px, w, lx, y);
        final r = _avg(px, w, rx, y);
        for (var x = left; x <= right; x++) {
          final t = (x - left) / (right - left);
          final i = (y * w + x) * 4;
          px[i] = (l[0] + (r[0] - l[0]) * t).round();
          px[i + 1] = (l[1] + (r[1] - l[1]) * t).round();
          px[i + 2] = (l[2] + (r[2] - l[2]) * t).round();
          px[i + 3] = 255;
        }
      }
    }

    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(px, w, h, ui.PixelFormat.rgba8888, done.complete);
    final out = await done.future;
    final png2 = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    return png2 == null ? png : png2.buffer.asUint8List();
  }

  static List<int> _avg(Uint8List px, int w, int x, int y) {
    var r = 0, g = 0, b = 0, n = 0;
    for (var dx = -2; dx <= 0; dx++) {
      final xx = (x + dx).clamp(0, w - 1).toInt();
      final i = (y * w + xx) * 4;
      r += px[i];
      g += px[i + 1];
      b += px[i + 2];
      n++;
    }
    return [r ~/ n, g ~/ n, b ~/ n];
  }
}