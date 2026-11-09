import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/analytics_service.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_score_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/generated_profile_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/career_studio_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_builder_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_draft_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_optimizer_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_report_view.dart';
import 'package:ai_business_card_maker/app/modules/clixa/widgets/clixa_sheets.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/paywall_triggers.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/usage_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// No store: the real `buy` logs its analytics, then fails as "unavailable".
class _Sub extends SubscriptionController {
  @override
  void onInit() {}
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
  late List<(String, Object?)> events;
  late _Sub sub;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
    await _loadFonts();
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    GeneratedProfileStore.clear();
    CareerScoreStore.clear();
    events = [];
    AnalyticsService.sink = (n, p) => events.add((n, p['source']));
    Get.put(ProfileStore());
    sub = _Sub();
    Get.put<SubscriptionController>(sub);
  });
  tearDown(() => AnalyticsService.sink = null);

  Future<void> pumpHome(WidgetTester t, Widget home) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(GetMaterialApp(home: home));
    await t.pump(const Duration(milliseconds: 300));
  }

  // ---------------------------------------------------------------------------
  group('Career: 1 build + 1 optimize, lifetime', () {
    const texts = (headline: 'H', about: 'A', experience: 'E');

    testWidgets('2nd BUILD is blocked: the builder never opens', (t) async {
      await pumpHome(t, const CareerStudioView());
      final usage = UsageService.to;

      // 1st build is free and opens the builder.
      expect(usage.canUse(UsageFeature.careerBuild), isTrue);
      await t.tap(find.text('Profile Builder'));
      await t.pumpAndSettle();
      expect(find.byType(ProfileBuilderView), findsOneWidget);
      Get.back();
      await t.pumpAndSettle();

      // The profile is generated: legacy store AND counter both say "used".
      GeneratedProfileStore.save(texts, 3);
      GeneratedProfileStore.save(texts, 2); // later edits cost nothing more
      await t.pump();
      expect(GeneratedProfileStore.built.value, isTrue);
      expect(usage.used(UsageFeature.careerBuild), 1);
      expect(usage.canUse(UsageFeature.careerBuild), isFalse);

      // 2nd tap: no new build - the saved profile opens (their own data).
      await t.tap(find.text('Profile Builder'));
      await t.pumpAndSettle();
      expect(find.byType(ProfileBuilderView), findsNothing);
      expect(find.byType(ProfileDraftView), findsOneWidget);
      Get.back();
      await t.pumpAndSettle();

      // Even if the legacy store is wiped, the counter still blocks a 2nd
      // build and the upgrade prompt appears.
      GeneratedProfileStore.clear();
      await t.pump();
      await t.tap(find.text('Profile Builder'));
      await t.pumpAndSettle();
      expect(find.byType(ProfileBuilderView), findsNothing);
      expect(find.text('Get unlimited builds with Pro'), findsOneWidget);

      // The prompt's upgrade button opens Paywall View 2 with its source.
      await t.tap(find.text('Get unlimited builds with Pro'));
      await t.pumpAndSettle();
      expect(find.byType(PaywallView2), findsOneWidget);
      expect(events, contains(('paywall_shown', 'career_builder')));
    });

    testWidgets('2nd OPTIMIZE is blocked with the upgrade prompt', (t) async {
      await pumpHome(t, const CareerStudioView());
      final usage = UsageService.to;

      await t.tap(find.text('Profile Optimizer'));
      await t.pumpAndSettle();
      expect(find.byType(ProfileOptimizerView), findsOneWidget);
      Get.back();
      await t.pumpAndSettle();

      CareerScoreStore.newScan(); // the scan ran
      CareerScoreStore.newScan(); // the same report again costs nothing more
      await t.pump();
      expect(CareerScoreStore.scanned.value, isTrue);
      expect(usage.used(UsageFeature.careerOptimize), 1);
      expect(usage.canUse(UsageFeature.careerOptimize), isFalse);

      await t.tap(find.text('Profile Optimizer'));
      await t.pumpAndSettle();
      expect(find.byType(ProfileOptimizerView), findsNothing);
      expect(find.text('Get unlimited scans with Pro'), findsOneWidget);
      expect(find.text('Open my last report'), findsOneWidget);
      await t.tap(find.text('Open my last report')); // never locked out of it
      await t.pumpAndSettle();
      expect(find.byType(ProfileReportView), findsOneWidget);
      Get.back();
      await t.pumpAndSettle();

      // Report cleared, counter still blocks.
      CareerScoreStore.clear();
      await t.pump();
      await t.tap(find.text('Profile Optimizer'));
      await t.pumpAndSettle();
      expect(find.byType(ProfileOptimizerView), findsNothing);
      expect(find.text('Get unlimited scans with Pro'), findsOneWidget);
      await t.tap(find.text('Get unlimited scans with Pro'));
      await t.pumpAndSettle();
      expect(find.byType(PaywallView2), findsOneWidget);
      expect(events, contains(('paywall_shown', 'career_optimizer')));
    });

    testWidgets('Pro is never blocked', (t) async {
      sub.isUserPro.value = true;
      GeneratedProfileStore.save(texts, 3);
      CareerScoreStore.newScan();
      await pumpHome(t, const CareerStudioView());
      await t.tap(find.text('Profile Optimizer'));
      await t.pumpAndSettle();
      expect(find.byType(ProfileOptimizerView), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  group('Pro icons', () {
    Future<void> openCrown(WidgetTester t) async {
      await pumpHome(
        t,
        Builder(
          builder: (_) => Scaffold(
            body: TextButton(
              onPressed: () => PaywallTriggers.show(PaywallTrigger.crown),
              child: const Text('crown'),
            ),
          ),
        ),
      );
      await t.tap(find.text('crown'));
      await t.pumpAndSettle();
    }

    testWidgets('a crown opens Paywall View 2: view, plan selected, dismiss', (
      t,
    ) async {
      await openCrown(t);
      expect(find.byType(PaywallView2), findsOneWidget);
      expect(events, contains(('paywall_shown', 'crown')));

      await t.tap(find.text('Continue')); // the buy button
      await t.pump();
      expect(events, contains(('plan_selected', 'crown')));
      await t.pumpAndSettle();

      Get.closeAllSnackbars(); // the "store unavailable" notice
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.close_rounded)); // the X
      await t.pumpAndSettle();
      expect(events, contains(('paywall_dismissed', 'crown')));
    });

    testWidgets('the Expert panel crown keeps the Pro sheet, same events', (
      t,
    ) async {
      await pumpHome(
        t,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showClixaUpgrade(context),
              child: const Text('expert'),
            ),
          ),
        ),
      );
      await t.tap(find.text('expert'));
      await t.pumpAndSettle();
      expect(find.byType(PaywallView2), findsNothing);
      expect(find.text('GO PRO'), findsOneWidget);
      expect(events, contains(('paywall_shown', 'expert_panel')));

      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(events, contains(('plan_selected', 'expert_panel')));

      await t.tapAt(const Offset(195, 20)); // outside the sheet: dismiss
      await t.pumpAndSettle();
      Get.closeAllSnackbars();
      await t.pump(const Duration(seconds: 6));
      await t.pumpAndSettle();
      expect(events, contains(('paywall_dismissed', 'expert_panel')));
    });

    test('source guard: only the Expert panel uses the Pro sheet', () {
      final offenders = <String>[];
      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = f.path;
        final src = f.readAsStringSync();
        final usesSheet = RegExp(
          r'\b(showUpgradeSheet|showClixaUpgrade)\(',
        ).hasMatch(src);
        const allowed = [
          'career_hub_sheets.dart', // defines it
          'clixa_sheets.dart', // defines showClixaUpgrade
          'clixa_view.dart', // the Expert panel crown
          'expert_panel_view.dart', // the Expert panel entry
        ];
        if (usesSheet && !allowed.any(path.endsWith)) offenders.add(path);

        // Every other CrownUpgradeButton goes to the paywall.
        if (!path.endsWith('clixa_view.dart')) {
          for (final m in RegExp(
            r'CrownUpgradeButton\([^;]*?onTap:\s*([^,]*),',
            dotAll: true,
          ).allMatches(src)) {
            final tap = m.group(1)!;
            if (!tap.contains('PaywallTriggers') &&
                !tap.contains('_openPaywall') &&
                !tap.contains('openProPaywall')) {
              offenders.add('$path -> $tap');
            }
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
