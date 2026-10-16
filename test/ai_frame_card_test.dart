import 'dart:io';
import 'dart:typed_data';

import 'package:ai_business_card_maker/app/core/utils/widget_image_renderer.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/model/card_element_model.dart';
import 'package:ai_business_card_maker/app/modules/template/model/template_live_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every landscape layout loads and fills with profile values', () async {
    final paths = await TemplateData.landscapeLayoutPaths();
    expect(paths, isNotEmpty);
    for (final path in paths) {
      final layout = await TemplateData.loadPath(path);
      expect(layout, isNotNull, reason: path);
      final filled = layout!.filled({
        'name': 'Ayesha Khan',
        'title': 'Designer',
        'company': 'Clixade',
        'phone': '+92 300 1234567',
        'email': 'ayesha@clixade.com',
        'website': 'clixade.com',
      });
      final texts = [
        ...filled.front.elements,
        ...filled.back.elements,
      ].where((e) => e.type == CardElementType.text).map((e) => e.text);
      expect(
        texts.any((t) => t.toLowerCase().contains('ayesha')),
        isTrue,
        reason: '$path shows the name',
      );
    }
  });

  testWidgets('a frame file is rendered off-screen at full size', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // A plain dark "frame", as Gemini would return.
      final frame = img.Image(width: 700, height: 400)
        ..clear(img.ColorRgb8(20, 30, 60));
      final file = File(
        '${Directory.systemTemp.createTempSync().path}/frame.png',
      )..writeAsBytesSync(img.encodePng(frame));

      const size = Size(340, 214);
      final png = await WidgetImageRenderer.render(
        Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        size: size,
        images: [FileImage(file)],
      );

      final out = img.decodePng(Uint8List.fromList(png))!;
      expect(out.width, 1020);
      expect(out.height, 642);
      // The frame's color, not an empty (transparent) render.
      final p = out.getPixel(500, 300);
      expect([p.r, p.g, p.b], [20, 30, 60]);
    });
  });
}
