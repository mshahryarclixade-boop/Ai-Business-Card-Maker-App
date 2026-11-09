import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/analytics_service.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_score_store.dart';
import 'package:ai_business_card_maker/app/modules/clixa/widgets/clixa_sheets.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
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
  String? lastSource;

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
    lastSource = source;
    if (succeeds) isUserPro.value = true;
    return succeeds;
  }
}

Future<void> _loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk == null) return;
  final loader = FontLoader('SFPro');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    final file = File('$sdk/bin/cache/artifacts/material_fonts/$f');
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
  }
  await loader.load();
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
    await _loadFonts();
  });

  late _FakeSub sub;
  late List<(String, Object?)> events;
  setUp(() {
    events = [];
    AnalyticsService.sink = (n, p) => events.add((n, p['source']));
  });
  tearDown(() => AnalyticsService.sink = null);

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

  // Every Career Pro entry opens the plans paywall (Paywall View 2); the Pro
  // sheet is only the Expert panel's.
  testWidgets('locked fix -> Paywall View 2; Pro afterwards opens that fix', (
    t,
  ) async {
    await pump(t, const ProfileReportView());
    await t.tap(find.text('No Featured section'));
    await t.pumpAndSettle();
    expect(find.byType(PaywallView2), findsOneWidget);
    expect(find.text('GO PRO'), findsNothing); // not the Pro sheet
    expect(events, contains(('paywall_shown', 'career_fix_locked')));

    sub.isUserPro.value = true; // bought
    Get.back();
    await t.pumpAndSettle();
    expect(find.byType(ProfileFixView), findsOneWidget);
    expect(find.text('No Featured section'), findsOneWidget);
  });

  testWidgets('"Fix all 7 with Pro" and the hub crown open Paywall View 2', (
    t,
  ) async {
    await pump(t, const ProfileReportView());
    await t.tap(find.text('Fix all 7 with Pro'));
    await t.pumpAndSettle();
    expect(find.byType(PaywallView2), findsOneWidget);
    expect(events, contains(('paywall_shown', 'career_fix_all')));
    Get.back();
    await t.pumpAndSettle();
    expect(events, contains(('paywall_dismissed', 'career_fix_all')));

    await pump(t, const CareerStudioView());
    await t.tap(find.byType(GestureDetector).at(1)); // crown button
    await t.pumpAndSettle();
    expect(find.byType(PaywallView2), findsOneWidget);
    expect(events, contains(('paywall_shown', 'crown')));
  });

  group('the Expert panel keeps its own Pro sheet', () {
    Future<void> open(WidgetTester t, {bool succeeds = true}) async {
      await pump(
        t,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showClixaUpgrade(context),
              child: const Text('crown'),
            ),
          ),
        ),
        succeeds: succeeds,
      );
      await t.tap(find.text('crown'));
      await t.pumpAndSettle();
    }

    testWidgets('subscribe -> You\'re Pro, source expert_panel', (t) async {
      await open(t);
      expect(find.byType(PaywallView2), findsNothing);
      expect(events, contains(('paywall_shown', 'expert_panel')));
      await t.tap(find.text('Monthly'));
      await t.pump();
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(sub.lastPlan, 'monthly');
      expect(sub.lastSource, 'expert_panel');
      expect(find.text("You're Pro"), findsOneWidget);
      expect(
        events.where((e) => e == ('paywall_dismissed', 'expert_panel')),
        isEmpty,
      );
    });

    testWidgets('a failed purchase keeps the sheet; Not now logs a dismiss', (
      t,
    ) async {
      await open(t, succeeds: false);
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(sub.buys, 1);
      expect(find.text("You're Pro"), findsNothing);
      await t.tap(find.text('Not now'));
      await t.pumpAndSettle();
      expect(events, contains(('paywall_dismissed', 'expert_panel')));
    });
  });
}
