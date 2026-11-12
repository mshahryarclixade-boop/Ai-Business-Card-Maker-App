import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/recent_design_card.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/cro_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/usage_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/watermark_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/widgets/card_watermark.dart';
import 'package:ai_business_card_maker/app/modules/paywall/widgets/pro_dialogs.dart';
import 'package:ai_business_card_maker/app/modules/recent designs/view/card_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_fonts.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Sub sub;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('wmk').path,
        );
    await GetStorage.init();
    await loadRobotoAsSfPro();
  });

  setUp(() async {
    Get.reset();
    resetProDialogGuard();
    await GetStorage().erase();
    sub = _Sub();
    Get.put<SubscriptionController>(sub);
    Get.put(UsageService());
  });

  Widget card() => const GetMaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          height: 180,
          child: Stack(fit: StackFit.expand, children: [ColoredBox(color: Colors.white), CardWatermark()]),
        ),
      ),
    ),
  );

  testWidgets('free: "Made with Business Card Maker" with a crown, top-right', (t) async {
    await t.pumpWidget(card());
    final text = find.text('Made with Business\nCard Maker');
    expect(text, findsOneWidget);
    final box = t.getRect(find.byType(SizedBox).first);
    final r = t.getRect(text);
    expect(r.right, greaterThan(box.center.dx)); // right half
    expect(r.top - box.top, lessThan(box.height / 3)); // top
    expect(find.byType(Icon), findsNothing);
    expect(t.widget<Text>(text).style!.color, kWatermarkGrey);
    expect(WatermarkService.lines.split('\n'), ['Made with Business', 'Card Maker']);
    expect(WatermarkService.defaultText, 'Made with Business Card Maker');
    expect(WatermarkService.text, 'Made with Business Card Maker');
    expect(CroMessages.defaults['watermark_text'], 'Made with Business Card Maker');
  });

  testWidgets('Pro sees no watermark, and it disappears at once after a purchase', (t) async {
    await t.pumpWidget(card());
    expect(find.text('Made with Business\nCard Maker'), findsOneWidget);
    sub.isUserPro.value = true;
    await t.pump();
    expect(find.text('Made with Business\nCard Maker'), findsNothing);
  });

  testWidgets('My Cards thumbnails show it; the editor-less default card does not', (t) async {
    final f = File('${Directory.systemTemp.path}/wm_thumb.png')..writeAsBytesSync(List.filled(70, 0));
    await t.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Column(children: [
          SizedBox(width: 200, child: RecentDesignCard(thumbnailFile: f, showWatermark: true)),
          SizedBox(width: 200, child: RecentDesignCard(thumbnailFile: f)),
        ]),
      ),
    ));
    expect(find.text('Made with Business\nCard Maker'), findsOneWidget);
  });

  testWidgets('download from My Cards asks about the watermark first, with no '
      '"Remove watermark" text; Pro downloads directly', (t) async {
    final f = File('${Directory.systemTemp.path}/wm_card.png')..writeAsBytesSync(List.filled(70, 0));
    final d = RecentDesign(
      id: '1', path: f.path, savedAt: DateTime(2026),
    );
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    Get.put(RecentDesignsService());
    await t.pumpWidget(GetMaterialApp(home: CardDetailView(design: d)));
    await t.pump();
    expect(find.text('Remove watermark'), findsNothing);
    expect(find.textContaining('Remove Watermark'), findsNothing);
    await t.tap(find.text('Download'));
    await t.pumpAndSettle();
    expect(find.text('Export without the watermark?'), findsOneWidget);
    expect(find.textContaining('Remove watermark'), findsNothing);
  });
}
