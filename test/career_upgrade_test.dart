import 'dart:io';

import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_score_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/career_studio_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_fix_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_report_view.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Stands in for the store: [buy] either "subscribes" or fails.
class _FakeSub extends SubscriptionController {
  _FakeSub({this.succeeds = true});
  final bool succeeds;
  int buys = 0;
  String? lastPlan;

  @override
  void onInit() {}

  @override
  Future<bool> buy(
    BuildContext context, {
    required String productId,
    required String plan,
    required String source,
  }) async {
    buys++;
    lastPlan = plan;
    if (succeeds) isUserPro.value = true;
    return succeeds;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
  });

  late _FakeSub sub;

  Future<void> pump(WidgetTester t, Widget home, {bool succeeds = true}) async {
    Get.reset();
    CareerScoreStore.clear();
    Get.put(ProfileStore());
    sub = _FakeSub(succeeds: succeeds);
    Get.put<SubscriptionController>(sub);
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(GetMaterialApp(home: home));
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('CS31-33: locked fix -> sheet -> subscribe -> You\'re Pro -> '
      'that fix opens', (t) async {
    await pump(t, const ProfileReportView());
    await t.tap(find.text('No Featured section'));
    await t.pumpAndSettle();

    // CS31: names the blocked fix.
    expect(find.text('GO PRO'), findsOneWidget);
    expect(find.text('Unlock the “Featured” fix'), findsOneWidget);
    expect(find.text('Unlock everything in Career Studio'), findsNothing);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);

    // Choose monthly, then Continue starts the purchase of that plan.
    await t.tap(find.text('Monthly'));
    await t.pump();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(sub.buys, 1);
    expect(sub.lastPlan, 'monthly');

    // CS33: "You're Pro" dialog (the store's own sheet is CS32, system UI).
    expect(find.text("You're Pro"), findsOneWidget);
    expect(
      find.textContaining('Everything in Career Studio is unlocked.'),
      findsOneWidget,
    );
    expect(find.text('Continue to your fixes'), findsOneWidget);
    expect(find.text('GO PRO'), findsNothing); // sheet is closed

    // Continue to your fixes -> the blocked fix opens.
    await t.tap(find.text('Continue to your fixes'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileFixView), findsOneWidget);
    expect(find.text('No Featured section'), findsOneWidget);
    expect(find.text('Pro · unlimited AI rewrites'), findsOneWidget);
  });

  testWidgets('"Fix all 7 with Pro": sheet, subscribe, then the first fix', (
    t,
  ) async {
    await pump(t, const ProfileReportView());
    await t.tap(find.text('Fix all 7 with Pro'));
    await t.pumpAndSettle();
    expect(find.text('Unlock everything in Career Studio'), findsOneWidget);
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(sub.lastPlan, 'yearly'); // the default plan
    expect(find.text("You're Pro"), findsOneWidget);
    await t.tap(find.text('Continue to your fixes'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileFixView), findsOneWidget);
    expect(find.text('Headline is only a job title'), findsOneWidget);
  });

  testWidgets('a cancelled or failed purchase keeps the sheet, no dialog', (
    t,
  ) async {
    await pump(t, const ProfileReportView(), succeeds: false);
    await t.tap(find.text('No Featured section'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(sub.buys, 1);
    expect(find.text("You're Pro"), findsNothing);
    expect(find.text('Unlock the “Featured” fix'), findsOneWidget);

    // Not now just closes it.
    await t.tap(find.text('Not now'));
    await t.pumpAndSettle();
    expect(find.text('Unlock the “Featured” fix'), findsNothing);
    expect(find.byType(ProfileFixView), findsNothing);
  });

  testWidgets('hub crown: subscribe -> You\'re Pro -> Continue closes it', (
    t,
  ) async {
    await pump(t, const CareerStudioView());
    await t.tap(find.byType(GestureDetector).at(1)); // crown button
    await t.pumpAndSettle();
    expect(find.text('Unlock everything in Career Studio'), findsOneWidget);
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text("You're Pro"), findsOneWidget);
    expect(find.text('Continue to your fixes'), findsNothing);
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text("You're Pro"), findsNothing);
    // The hub now shows the Pro state.
    expect(find.text('Pro plan'), findsOneWidget);
  });
}
