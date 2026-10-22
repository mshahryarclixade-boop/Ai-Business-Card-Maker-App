import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_controller.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/view/card_editor_view.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/widgets/canvas.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/widgets/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'dart:typed_data';

void main() {
  late CardEditorController c;

  Future<void> boot(WidgetTester t) async {
    Get.reset();
    c = Get.put(CardEditorController());
    await t.pumpWidget(const GetMaterialApp(home: SizedBox()));
  }

  testWidgets('undo / redo restores the previous background color', (t) async {
    await boot(t);
    const red = Color(0xFFFF3B30);
    const blue = Color(0xFF007AFF);

    c.setBackgroundColor(red);
    expect(c.backgroundColor.value, red);
    // Far enough apart to be two separate changes (real time, not fake).
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    c.setBackgroundColor(blue);
    expect(c.backgroundColor.value, blue);

    c.undo();
    expect(c.backgroundColor.value, red);
    c.undo();
    expect(c.backgroundColor.value, const Color(0xFFFFFFFF));
    expect(c.canUndo.value, isFalse);

    c.redo();
    expect(c.backgroundColor.value, red);
    c.redo();
    expect(c.backgroundColor.value, blue);
    expect(c.canRedo.value, isFalse);
  });

  testWidgets('a drag in the color picker is a single undo step', (t) async {
    await boot(t);
    for (final v in [0x11, 0x22, 0x33, 0x44]) {
      c.setBackgroundColor(Color(0xFF000000 | v));
    }
    c.undo();
    expect(c.backgroundColor.value, const Color(0xFFFFFFFF));
    expect(c.canUndo.value, isFalse);
  });

  testWidgets('undo of a background change keeps the elements', (t) async {
    await boot(t);
    c.addText();
    c.setBackgroundColor(const Color(0xFF000000));
    c.undo();
    expect(c.backgroundColor.value, const Color(0xFFFFFFFF));
    expect(c.elements.length, 1);
    c.undo(); // the add
    expect(c.elements, isEmpty);
  });

  testWidgets('moving text to the other side can be undone and redone', (
    t,
  ) async {
    await boot(t);
    c.addText();
    c.addText();
    final moved = c.elements.first;
    c.selectElement(moved.id);

    c.moveSelectedToOtherSide();
    await t.pump(const Duration(seconds: 3));
    expect(c.elements.map((e) => e.id), isNot(contains(moved.id)));
    expect(c.canUndo.value, isTrue);

    c.undo();
    // Back on this side, in its old place in the layer order, and gone from
    // the other side.
    expect(c.elements.first.id, moved.id);
    expect(c.elements.length, 2);
    c.switchToSide(1);
    expect(c.elements.where((e) => e.id == moved.id), isEmpty);
    c.switchToSide(0);
    expect(c.elements.first.id, moved.id);

    c.redo();
    expect(c.elements.map((e) => e.id), isNot(contains(moved.id)));
    expect(c.elements.length, 1);
    c.switchToSide(1);
    expect(c.elements.where((e) => e.id == moved.id).length, 1);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('moving back from the other side is undoable too', (t) async {
    await boot(t);
    c.addText();
    c.selectElement(c.elements.first.id);
    c.moveSelectedToOtherSide(); // front -> back
    await t.pump(const Duration(seconds: 3));
    c.switchToSide(1);
    final el = c.elements.firstWhere((e) => e.type.name == 'text');
    c.selectElement(el.id);
    final before = c.elements.length;
    c.moveSelectedToOtherSide(); // back -> front
    await t.pump(const Duration(seconds: 3));
    expect(c.elements.length, before - 1);
    c.undo();
    expect(c.elements.length, before);
    c.switchToSide(0);
    expect(c.elements.where((e) => e.id == el.id), isEmpty);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('while saving, the card canvas shows the frozen picture', (
    t,
  ) async {
    await boot(t);
    await t.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: CardCanvas(controller: c)),
      ),
    );
    expect(find.byType(Image), findsNothing);
    // 1x1 transparent PNG.
    c.captureFreeze.value = Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, //
      0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
      0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63,
      0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4,
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
      0x82,
    ]);
    await t.pump();
    expect(find.byType(Image), findsOneWidget);
    c.captureFreeze.value = null;
    await t.pump();
    expect(find.byType(Image), findsNothing);
  });

  group('color palette', () {
    testWidgets('fills even rows and has no overflow at any width', (t) async {
      for (final w in [200.0, 280.0, 340.0, 390.0, 600.0]) {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: w,
                  child: ColorPaletteGrid(
                    onSelect: (_) {},
                    onOpenCustomPicker: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull, reason: 'width $w');
        expect(find.byType(PaletteSwatch), findsNWidgets(kColorPalette.length));
        expect(find.byType(MultiColorSwatch), findsOneWidget);
      }
      // 39 colors + the rainbow tile = 4 full rows of 10 on a phone.
      expect(kColorPalette.length, 39);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 358,
                child: ColorPaletteGrid(
                  onSelect: (_) {},
                  onOpenCustomPicker: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final ys = {
        for (final e in find.byType(PaletteSwatch).evaluate())
          t.getTopLeft(find.byWidget(e.widget)).dy.round(),
      };
      expect(ys.length, 4, reason: '40 swatches in rows of 10');
    });

    testWidgets('the picked color shows a tick', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPaletteGrid(
              selected: kColorPalette[3],
              onSelect: (_) {},
              onOpenCustomPicker: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    test('colors are unique', () {
      expect(kColorPalette.toSet().length, kColorPalette.length);
    });
  });

  group('text size with the keyboard open', () {
    for (final size in const [
      Size(320, 480),
      Size(360, 640),
      Size(390, 844),
      Size(820, 1180),
    ]) {
      testWidgets(
        'no overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (t) async {
          Get.reset();
          t.view.physicalSize = size * 2;
          t.view.devicePixelRatio = 2;
          // Soft keyboard: ~40% of the screen.
          t.view.viewInsets = FakeViewPadding(bottom: size.height * 2 * 0.4);
          addTearDown(t.view.reset);
          addTearDown(t.view.resetViewInsets);

          await t.pumpWidget(const GetMaterialApp(home: CardEditorView()));
          await t.pump();
          final ctl = Get.find<CardEditorController>();
          ctl.addText();
          await t.pump();
          ctl.openTextStyleBar();
          await t.pump();
          ctl.toggleStylePanel('size');
          await t.pump(const Duration(milliseconds: 300));
          expect(find.byType(TextField), findsOneWidget);

          await t.tap(find.byType(TextField));
          await t.pump(const Duration(milliseconds: 300));
          await t.enterText(find.byType(TextField), '24');
          await t.pump(const Duration(milliseconds: 300));
          expect(t.takeException(), isNull);
          expect(ctl.selectedElement?.fontSize, 24);
        },
      );
    }
  });
}
