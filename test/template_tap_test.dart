import 'dart:async';
import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/home/controller/home_controller.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/template/widget/template_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('tt').path,
        );
    await GetStorage.init();
  });

  testWidgets('every template can be tapped on Home: it is selected with its live '
      'preview, one after the other', (t) async {
    Get.reset();
    Get.put(ProfileStore());
    Get.put(RecentDesignsService());
    await t.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final hc = HomeController(); // (its onReady needs the whole app's services: not started)
    final tc = hc.templates;
    await t.runAsync(() async {
      for (var i = 0; i < 100 && tc.isLoading.value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    final items = [...tc.allTemplates];
    expect(items, hasLength(20));
    for (final item in [hc.orderedTemplates(items).first, ...items]) {
      // The tests have no network: the Google fonts fail in the background, as
      // they would offline. That must not matter, so those errors are ignored.
      await t.runAsync(() async {
        final done = Completer<void>();
        runZonedGuarded(() async {
          await hc.previewTemplateTap(item);
          await Future<void>.delayed(const Duration(milliseconds: 30));
          done.complete();
        }, (e, s) {});
        await done.future;
      });
      expect(hc.previewTemplate.value?.id, item.id, reason: '${item.id} selected');
      expect(hc.previewData.value, isNotNull, reason: '${item.id} live preview');
      hc.cancelPreview();
    }
  });

  testWidgets('every template card in the Template tab reacts to a tap', (t) async {
    Get.reset();
    Get.put(ProfileStore());
    Get.put(RecentDesignsService());
    await t.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final tc = HomeController().templates;
    await t.runAsync(() async {
      for (var i = 0; i < 100 && tc.isLoading.value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    final items = [...tc.allTemplates];
    t.view.physicalSize = const Size(393 * 2, 6000 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final tapped = <String>[];
    await t.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            for (final item in items)
              SizedBox(
                width: 170,
                child: TemplateCard(
                  key: ValueKey(item.id), item: item, isSaved: false, onHeartTap: () {},
                  onTap: () => tapped.add(item.id),
                ),
              ),
          ]),
        ),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await t.pump();
    for (final item in items) {
      await t.tapAt(t.getRect(find.byKey(ValueKey(item.id))).center);
      await t.pump();
    }
    expect(tapped, items.map((e) => e.id).toList());
  });

  test('the tap never waits for a font download (Home previews at once, fonts '
      'are refined in the background)', () {
    final src = File('lib/app/modules/home/controller/home_controller.dart').readAsStringSync();
    final start = src.indexOf('Future<void> previewTemplateTap');
    final body = src.substring(start, src.indexOf('Future<void>? _fontRefine'));
    expect(body.contains('await AiFrameCardBuilder.loadFonts'), isFalse);
    expect(body, contains('unawaited(_fontRefine)'));
    expect(src, contains('await _fontRefine?.timeout'));
  });
}
