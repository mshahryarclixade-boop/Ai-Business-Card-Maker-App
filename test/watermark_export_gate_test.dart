import 'dart:io';

import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/usage_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/watermark_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
import 'package:ai_business_card_maker/app/modules/paywall/widgets/pro_dialogs.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_fonts.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}

  @override
  Future<bool> buy(
    BuildContext context, {
    required String productId,
    required String plan,
    required String source,
  }) async {
    isUserPro.value = true;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Sub sub;
  bool? result;
  var calls = 0;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('wg').path,
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
    Get.put(ProfileStore());
    Get.put(UsageService());
    result = null;
    calls = 0;
  });

  /// The Home "Save / Share card image" step: ask first, export only if
  /// [WatermarkService.confirmExport] says so.
  Future<void> run(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                result = await WatermarkService.confirmExport(screen: 'home');
                if (result!) calls++; // the export (front + back) runs once
              },
              child: const Text('save'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('save'));
    await t.pumpAndSettle();
  }

  testWidgets('Pro exports directly: no dialog, no watermark', (t) async {
    sub.isUserPro.value = true;
    await run(t);
    expect(find.text('Export without the watermark?'), findsNothing);
    expect(result, isTrue);
    expect(WatermarkService.applies, isFalse);
  });

  testWidgets('free: the dialog asks first', (t) async {
    await run(t);
    expect(find.text('Export without the watermark?'), findsOneWidget);
    expect(find.text('Yes, remove it'), findsOneWidget);
    expect(find.text('No, keep the watermark'), findsOneWidget);
    expect(result, isNull); // nothing exported yet
  });

  testWidgets('No: export goes on WITH the watermark', (t) async {
    await run(t);
    await t.tap(find.text('No, keep the watermark'));
    await t.pumpAndSettle();
    expect(find.byType(PaywallView2), findsNothing);
    expect(result, isTrue);
    expect(calls, 1);
    expect(WatermarkService.applies, isTrue); // still stamped
  });

  testWidgets('Yes opens the watermark paywall; closing it exports nothing',
      (t) async {
    await run(t);
    await t.tap(find.text('Yes, remove it'));
    await t.pumpAndSettle();
    expect(find.byType(PaywallView2), findsOneWidget);
    expect(find.text('Export without the watermark'), findsOneWidget); // headline
    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pumpAndSettle();
    expect(find.byType(PaywallView2), findsNothing);
    expect(result, isFalse);
    expect(calls, 0); // never a clean export without Pro
    expect(WatermarkService.applies, isTrue);
  });

  testWidgets('Yes then a successful purchase: clean export continues',
      (t) async {
    await run(t);
    await t.tap(find.text('Yes, remove it'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue')); // monthly is selected by default
    await t.pumpAndSettle();
    await t.tap(find.text('Start creating')); // "Welcome to Pro" dialog
    await t.pumpAndSettle();
    expect(result, isTrue);
    expect(calls, 1);
    expect(WatermarkService.applies, isFalse); // front and back come out clean
  });
}
