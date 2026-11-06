import 'dart:io';
import 'dart:typed_data';

import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/core/widgets/app_dialog.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_controller.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/view/card_editor_view.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/widgets/canvas.dart';
import 'package:ai_business_card_maker/app/core/widgets/side_switcher.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/recent_design_card.dart';
import 'package:ai_business_card_maker/app/modules/recent designs/view/card_detail_view.dart';
import 'package:ai_business_card_maker/app/modules/recent designs/view/my_cards_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;

Uint8List _png() => Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 5)));

Map<String, dynamic> _blank() => {
  'orientation': 'landscape',
  'backgroundColor': 0xFFFFFFFF,
  'backgroundImagePath': null,
  'backgroundTemplate': null,
  'elements': <dynamic>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('ui').path,
        );
    await GetStorage.init();
  });

  late RecentDesignsService service;

  Future<void> boot(WidgetTester t) async {
    Get.reset();
    await GetStorage().erase();
    service = RecentDesignsService();
    Get.put(service);
  }

  Future<RecentDesign> add(WidgetTester t, {String title = ''}) async {
    final d = await t.runAsync(() => service.save(_png(), backThumbnailBytes: _png(), designData: _blank(), title: title));
    return d!;
  }

  Future<void> realWait(WidgetTester t, [int ms = 250]) async {
    await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    await t.pump();
  }

  group('My Cards list', () {
    testWidgets('follows the service: a deleted card goes, an edited card shows its new picture', (t) async {
      await boot(t);
      final a = await add(t);
      final b = await add(t);
      await t.pumpWidget(const GetMaterialApp(home: MyCardsView()));
      await t.pump();
      expect(find.byType(RecentDesignCard), findsNWidgets(2));
      await realWait(t, 400); // let the pictures load before any is replaced

      // Edited in place: the list shows the new picture at once.
      final updated = (await t.runAsync(() => service.update(a.id, front: _png(), back: _png(), designData: _blank())))!;
      await t.pump();
      final shown = [for (final w in t.widgetList<RecentDesignCard>(find.byType(RecentDesignCard))) w.thumbnailFile!.path];
      expect(shown, contains(updated.path));
      expect(shown, isNot(contains(a.path)));

      await t.runAsync(() => service.delete(b.id));
      await t.pump();
      expect(find.byType(RecentDesignCard), findsOneWidget);
      await t.runAsync(() => service.delete(a.id));
      await t.pump();
      expect(find.byType(RecentDesignCard), findsNothing);
    });
  });

  group('card preview', () {
    testWidgets('the app-bar Delete asks first, then removes the card and closes', (t) async {
      await boot(t);
      final d = await add(t);
      await t.pumpWidget(GetMaterialApp(home: const Scaffold(), getPages: const []));
      Get.to(() => CardDetailView(design: d));
      await t.pumpAndSettle();

      // Asked first: Cancel keeps it.
      await t.tap(find.byIcon(Icons.delete_outline_rounded));
      await t.pumpAndSettle();
      expect(find.text('Delete this template?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(service.designs.length, 1);
      expect(find.byType(CardDetailView), findsOneWidget);

      await t.tap(find.byIcon(Icons.delete_outline_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete'));
      // The delete touches files: real time has to pass between frames.
      for (var i = 0; i < 40 && find.byType(CardDetailView).evaluate().isNotEmpty; i++) {
        await realWait(t, 100);
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.pumpAndSettle();
      expect(service.designs, isEmpty);
      expect(find.byType(CardDetailView), findsNothing);
    });

    testWidgets('Delete sits in the app bar, the card scrolls, and there is no extra top gap', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await boot(t);
      final d = await add(t);
      await t.pumpWidget(GetMaterialApp(home: CardDetailView(design: d)));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);

      // Delete is the app bar's trailing button (top right), not at the bottom.
      final del = t.getRect(find.byIcon(Icons.delete_outline_rounded));
      expect(del.center.dy, lessThan(80));
      expect(del.center.dx, greaterThan(390 - 80));
      expect(find.text('Delete Template'), findsNothing); // no bottom button any more
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // The existing ScrollView holds the two cards.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final firstCard = t.getRect(find.byType(AspectRatio).first);
      final appBarBottom = t.getRect(find.byIcon(Icons.arrow_back_rounded)).bottom;
      expect(firstCard.top - appBarBottom, lessThan(40), reason: 'the card starts right under the app bar');
    });

    testWidgets('shows the card as it is now (follows the service)', (t) async {
      await boot(t);
      final d = await add(t);
      await t.pumpWidget(GetMaterialApp(home: CardDetailView(design: d)));
      await t.pump();
      final updated = (await t.runAsync(() => service.update(d.id, front: _png(), back: _png(), designData: _blank())))!;
      await t.pump();
      final files = [
        for (final w in t.widgetList<Container>(find.byType(Container)))
          if (w.decoration is BoxDecoration && (w.decoration as BoxDecoration).image?.image is FileImage)
            ((w.decoration as BoxDecoration).image!.image as FileImage).file.path,
      ];
      expect(files, contains(updated.path));
      expect(files, isNot(contains(d.path)));
    });
  });

  group('canvas', () {
    Future<CardEditorController> openEditor(WidgetTester t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      Get.reset();
      await t.pumpWidget(const GetMaterialApp(home: CardEditorView()));
      await t.pump();
      final c = Get.find<CardEditorController>();
      c.addText();
      c.closeToolPanel();
      c.selectElement(null);
      await t.pump();
      return c;
    }

    testWidgets('the Background tool has only colours (no gallery / templates buttons)', (t) async {
      final c = await openEditor(t);
      c.selectTool('background');
      await t.pump();
      expect(find.text('Upload from Gallery'), findsNothing);
      expect(find.text('Background Templates'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('the Front / Back switch sits right under Save', (t) async {
      await openEditor(t);
      final save = t.getRect(find.text('Save'));
      final switcher = t.getRect(find.byType(SideSwitcher));
      expect(switcher.top, greaterThan(save.bottom));
      expect(switcher.right, greaterThan(390 - 40), reason: 'at the right edge, under Save');
      expect((switcher.center.dx - save.center.dx).abs(), lessThan(60));
    });

    testWidgets('there are no zoom controls', (t) async {
      await openEditor(t);
      expect(find.byIcon(Icons.fit_screen_rounded), findsNothing);
      expect(find.byIcon(Icons.zoom_in), findsNothing);
      expect(find.byIcon(Icons.zoom_out), findsNothing);
    });

    testWidgets('one finger still drags an element, one pixel for one card unit at fit', (t) async {
      final c = await openEditor(t);
      final g = await t.startGesture(t.getCenter(find.byType(CanvasElementWidget).first));
      await g.moveBy(const Offset(-40, 0)); // past the touch slop
      await t.pump();
      final p0 = c.elements.first.position;
      await g.moveBy(const Offset(-30, 0));
      await t.pump();
      final p1 = c.elements.first.position;
      await g.up();
      await t.pump(const Duration(seconds: 1));
      expect((p0 - p1).dx, closeTo(30, 0.5));
    });

    testWidgets('double tap on a text opens the themed edit dialog and applies the change', (t) async {
      final c = await openEditor(t);
      final target = t.getCenter(find.byType(CanvasElementWidget).first);
      await t.tapAt(target);
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(target);
      await t.pumpAndSettle();
      expect(find.byType(AppDialogCard), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await t.enterText(find.byType(TextField), 'Hello card');
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(c.elements.first.text, 'Hello card');
      expect(find.byType(AppDialogCard), findsNothing);

      // Cancel leaves the text alone.
      await t.tapAt(target);
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(target);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'nope');
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(c.elements.first.text, 'Hello card');
    });
  });
}
