import 'dart:typed_data';

import 'package:ai_business_card_maker/app/modules/profile_setup/widgets/logo_background_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _logo() {
  final image = img.Image(width: 60, height: 60, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
  img.fillCircle(image, x: 30, y: 30, radius: 20, color: img.ColorRgba8(200, 20, 20, 255));
  return Uint8List.fromList(img.encodePng(image));
}

Future<Uint8List?> _open(WidgetTester t, Uint8List logo, Future<void> Function() act) async {
  Uint8List? result;
  var done = false;
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (c) => TextButton(
        onPressed: () async {
          result = await showLogoBackgroundSheet(c, logo);
          done = true;
        },
        child: const Text('open'),
      ),
    ),
  ));
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  await act();
  await t.pumpAndSettle();
  expect(done, isTrue);
  return result;
}

void main() {
  testWidgets('Remove Background -> preview -> Apply returns the transparent logo', (t) async {
    final out = await _open(t, _logo(), () async {
      expect(find.text('Remove Background'), findsOneWidget);
      expect(find.text('Keep Original'), findsOneWidget);
      await t.tap(find.text('Remove Background'));
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
      await t.pump();
      await t.pump();
      expect(find.text('Apply'), findsOneWidget);
      await t.tap(find.text('Apply'));
    });
    expect(out, isNotNull);
    expect(img.decodePng(out!)!.getPixel(1, 1).a, 0);
  });

  testWidgets('Keep Original returns null', (t) async {
    final out = await _open(t, _logo(), () async {
      await t.tap(find.text('Keep Original'));
    });
    expect(out, isNull);
  });
}
