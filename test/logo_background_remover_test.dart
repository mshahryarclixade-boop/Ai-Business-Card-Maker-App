import 'dart:typed_data';

import 'package:ai_business_card_maker/app/modules/profile_setup/service/logo_background_remover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// 100x100, [bg] background, a red ring (r 30..40) with a [bg] coloured disc
/// inside it (the "white letter counter" that must be kept).
Uint8List _logo({int bg = 0xFFFFFF}) {
  final image = img.Image(width: 100, height: 100, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(bg >> 16, (bg >> 8) & 255, bg & 255, 255));
  img.fillCircle(image, x: 50, y: 50, radius: 40, color: img.ColorRgba8(220, 30, 30, 255));
  img.fillCircle(image, x: 50, y: 50, radius: 28, color: img.ColorRgba8(bg >> 16, (bg >> 8) & 255, bg & 255, 255));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  _moreTests();
  test('removes the outside background, keeps the enclosed white and colours', () {
    final out = LogoBackgroundRemover.removeSync(_logo())!;
    final r = img.decodePng(out)!;
    expect(r.getPixel(2, 2).a, 0); // outside corner
    expect(r.getPixel(50, 50).a, 255); // enclosed white stays
    final ring = r.getPixel(50, 15); // on the red ring
    expect(ring.a, 255);
    expect([ring.r, ring.g, ring.b], [220, 30, 30]);
  });

  test('a non-white (coloured) background is removed too', () {
    final out = LogoBackgroundRemover.removeSync(_logo(bg: 0xE8F0FF))!;
    final r = img.decodePng(out)!;
    expect(r.getPixel(98, 98).a, 0);
    expect(r.getPixel(50, 50).a, 255);
  });

  test('no clear background -> null', () {
    final image = img.Image(width: 40, height: 40, numChannels: 4);
    img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
    img.fillRect(image, x1: 20, y1: 0, x2: 40, y2: 40, color: img.ColorRgba8(0, 0, 0, 255));
    expect(LogoBackgroundRemover.removeSync(Uint8List.fromList(img.encodePng(image))), isNull);
  });

  test('a logo that already is transparent -> null', () {
    final image = img.Image(width: 40, height: 40, numChannels: 4);
    img.fillCircle(image, x: 20, y: 20, radius: 10, color: img.ColorRgba8(0, 0, 0, 255));
    expect(LogoBackgroundRemover.removeSync(Uint8List.fromList(img.encodePng(image))), isNull);
  });
}

void _moreTests() {
  test('a logo touching the edges still gets its background removed', () {
    final image = img.Image(width: 100, height: 100, numChannels: 4);
    img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
    // A red bar running off the left edge, a white counter inside it.
    img.fillRect(image, x1: 0, y1: 30, x2: 70, y2: 70, color: img.ColorRgba8(200, 20, 20, 255));
    img.fillRect(image, x1: 20, y1: 42, x2: 40, y2: 58, color: img.ColorRgba8(255, 255, 255, 255));
    final out = LogoBackgroundRemover.removeSync(Uint8List.fromList(img.encodePng(image)))!;
    final r = img.decodePng(out)!;
    expect(r.getPixel(95, 5).a, 0);
    expect(r.getPixel(30, 50).a, 255); // enclosed white stays
    expect(r.getPixel(10, 35).a, 255);
  });

  test('JPEG noise on the background does not stop the removal', () {
    final image = img.Image(width: 120, height: 120);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    img.fillCircle(image, x: 60, y: 60, radius: 40, color: img.ColorRgb8(30, 90, 200));
    final jpg = Uint8List.fromList(img.encodeJpg(image, quality: 60));
    final out = LogoBackgroundRemover.removeSync(jpg)!;
    final r = img.decodePng(out)!;
    expect(r.getPixel(3, 3).a, 0);
    expect(r.getPixel(60, 60).a, 255);
  });
}
