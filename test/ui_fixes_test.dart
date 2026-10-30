import 'dart:io';

import 'package:ai_business_card_maker/app/core/widgets/tap_target.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_controller.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_symbols_controller_ext.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/model/symbol_asset_items.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/model/qr_entry.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/service/qr_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('ui_fixes').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir,
        );
    await GetStorage.init();
  });

  group('TapTarget', () {
    testWidgets('a small icon is hit from up to 48 px around it, its size unchanged', (t) async {
      var taps = 0;
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(100),
              child: TapTarget(
                child: GestureDetector(
                  key: key,
                  onTap: () => taps++,
                  child: const SizedBox(width: 16, height: 16, child: Icon(Icons.close, size: 14)),
                ),
              ),
            ),
          ),
        ),
      );
      expect(t.getSize(find.byKey(key)), const Size(16, 16), reason: 'the layout is unchanged');
      final c = t.getCenter(find.byKey(key));
      await t.tapAt(c);
      expect(taps, 1);
      await t.tapAt(c + const Offset(20, 0)); // 12 px outside the icon, inside 48 px
      await t.tapAt(c + const Offset(0, -20));
      expect(taps, 3);
      await t.tapAt(c + const Offset(40, 0)); // too far
      await t.tapAt(c + const Offset(0, 40));
      expect(taps, 3, reason: 'only the 48 px area around the icon');
    });

    testWidgets('a widget that is already large is not changed', (t) async {
      var taps = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Center(
            child: TapTarget(
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => taps++, child: const SizedBox(width: 80, height: 80)),
            ),
          ),
        ),
      );
      await t.tapAt(t.getCenter(find.byType(SizedBox).first) + const Offset(60, 0));
      expect(taps, 0, reason: 'no extra reach beyond a big widget');
      await t.tap(find.byType(GestureDetector));
      expect(taps, 1);
    });

    testWidgets('the extra area does not steal taps from a neighbour that is hit directly', (t) async {
      var a = 0, b = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TapTarget(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => a++, child: const SizedBox(width: 20, height: 20))),
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => b++, child: const SizedBox(width: 60, height: 40)),
              ],
            ),
          ),
        ),
      );
      final second = find.byType(GestureDetector).last;
      await t.tapAt(t.getCenter(second));
      expect((a, b), (0, 1), reason: 'a tap in the neighbour\'s own area goes to the neighbour');
    });
  });

  group('Canvas undo', () {
    Future<CardEditorController> boot(WidgetTester t) async {
      Get.reset();
      final c = Get.put(CardEditorController());
      await t.pumpWidget(const GetMaterialApp(home: SizedBox()));
      return c;
    }

    testWidgets('the FIRST sticker can be undone, and redone', (t) async {
      final c = await boot(t);
      expect(c.canUndo.value, isFalse);
      c.addSocialSticker(kSocialIcons.first);
      expect(c.elements.length, 1);
      expect(c.canUndo.value, isTrue, reason: 'adding it is an Undo step');
      c.undo();
      expect(c.elements, isEmpty);
      expect(c.canRedo.value, isTrue);
      c.redo();
      expect(c.elements.length, 1);
    });

    testWidgets('every added sticker undoes one at a time, mixed with text and symbols', (t) async {
      final c = await boot(t);
      c.addSocialSticker(kSocialIcons.first);
      c.addArrowSticker(kArrowStyles.first);
      c.addText();
      c.addIconSticker(kGeneralIcons.first);
      expect(c.elements.length, 4);
      for (var n = 3; n >= 0; n--) {
        c.undo();
        expect(c.elements.length, n);
      }
      expect(c.canUndo.value, isFalse);
      for (var n = 1; n <= 4; n++) {
        c.redo();
        expect(c.elements.length, n);
      }
    });

    testWidgets('undo of other widgets (text, symbol) is unchanged', (t) async {
      final c = await boot(t);
      c.addText();
      c.addSymbol('★');
      c.undo();
      expect(c.elements.length, 1);
      c.undo();
      expect(c.elements, isEmpty);
    });
  });

  group('QR Preview selection', () {
    QrEntry entry(String id, String name) => QrEntry(
      id: id,
      form: {'fullName': name},
      styleId: 'classic',
      createdAt: DateTime(2026, 1, 1),
    );

    test('Preview makes the chosen saved code the one Home and Show QR Code use', () {
      QrStore.clear();
      QrStore.put(entry('a', 'Old'));
      QrStore.put(entry('b', 'Newest'));
      expect(QrStore.defaultEntry!.id, 'b', reason: 'newest by default, as before');
      QrStore.select('a');
      expect(QrStore.defaultEntry!.id, 'a');
      expect(QrStore.defaultEntry!.form['fullName'], 'Old', reason: 'its own saved data');
      QrStore.select('missing');
      expect(QrStore.defaultEntry!.id, 'a', reason: 'an unknown id changes nothing');
    });

    test('a new code is shown first again, editing keeps the pick, deleting the pick falls back', () {
      QrStore.clear();
      QrStore.put(entry('a', 'Old'));
      QrStore.put(entry('b', 'Second'));
      QrStore.select('a');
      QrStore.put(entry('a', 'Old edited')); // edit
      expect(QrStore.defaultEntry!.form['fullName'], 'Old edited');
      QrStore.put(entry('c', 'Brand new'));
      expect(QrStore.defaultEntry!.id, 'c');
      QrStore.select('b');
      QrStore.remove('b');
      expect(QrStore.defaultEntry!.id, 'c', reason: 'back to the newest');
      QrStore.clear();
      expect(QrStore.defaultEntry, isNull);
    });

    test('the pick survives a restart (reload) and is dropped if its code is gone', () {
      QrStore.clear();
      QrStore.put(entry('a', 'Old'));
      QrStore.put(entry('b', 'Newest'));
      QrStore.select('a');
      QrStore.reload();
      expect(QrStore.defaultEntry!.id, 'a');
    });
  });
}
