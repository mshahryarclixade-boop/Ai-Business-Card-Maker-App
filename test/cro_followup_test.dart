import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/analytics_service.dart';
import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/clixa/widgets/clixa_sheets.dart';
import 'package:ai_business_card_maker/app/modules/main_nav/controller/main_nav_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/paywall_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/paywall_triggers.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/revenue_cat_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_screen.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/view/first_card_ready_view.dart';
import 'package:ai_business_card_maker/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'test_fonts.dart';


/// A store that answers with the given products.
class _Sub extends SubscriptionController {
  _Sub([this.catalog = const {}]);
  final Map<String, StoreProduct> catalog;

  @override
  void onInit() {}

  @override
  StoreProduct? productFor(String productId) => catalog[productId];
}

StoreProduct _product(String id, double price, String text) =>
    StoreProduct(id, 'd', id, price, text, 'USD');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<(String, Map<String, Object>)> events;
  var dayNow = DateTime(2026, 1, 1, 9);

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
    await loadRobotoAsSfPro();
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    dayNow = DateTime(2026, 1, 1, 9);
    events = [];
    AnalyticsService.sink = (n, p) => events.add((n, p));
    Get.put(ProfileStore());
  });
  tearDown(() => AnalyticsService.sink = null);

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  // 1 -------------------------------------------------------------- saving
  group('"Save N%" is computed from the live store prices', () {
    test('store prices win; the defaults are only the fallback', () {
      // No store answer yet: the default prices (29.99 vs 12 x 6.99) = 64%.
      Get.put<SubscriptionController>(_Sub());
      expect(PaywallConfig.defaults.yearly.saveBadge, 'Save 64%');
      expect(
        PaywallConfig.defaults.yearly.perMonthNote,
        r'$2.50/month, billed yearly',
      );

      // The store says monthly $9.99 and yearly $35.88: 70% off, $2.99/month.
      Get.reset();
      Get.put<SubscriptionController>(
        _Sub({
          RevenueCatHelper.monthlyProductId: _product('m', 9.99, r'$9.99'),
          RevenueCatHelper.yearlyProductId: _product('y', 35.88, r'$35.88'),
        }),
      );
      final y = PaywallConfig.defaults.yearly;
      expect(y.saveBadge, 'Save 70%'); // 1 - 35.88/119.88 = 70.07%
      expect(y.perMonthNote, r'$2.99/month, billed yearly');
      expect(y.price, r'$35.88');
      expect(PaywallConfig.defaults.monthly.price, r'$9.99');

      // Another store price: the label follows it (not a fixed number).
      Get.reset();
      Get.put<SubscriptionController>(
        _Sub({
          RevenueCatHelper.monthlyProductId: _product('m', 6.99, r'$6.99'),
          RevenueCatHelper.yearlyProductId: _product('y', 24.99, r'$24.99'),
        }),
      );
      expect(PaywallConfig.defaults.yearly.saveBadge, 'Save 70%');
      Get.reset();
      Get.put<SubscriptionController>(
        _Sub({
          RevenueCatHelper.monthlyProductId: _product('m', 6.99, r'$6.99'),
          RevenueCatHelper.yearlyProductId: _product('y', 41.94, r'$41.94'),
        }),
      );
      expect(PaywallConfig.defaults.yearly.saveBadge, 'Save 50%');
    });
  });


  // 4 --------------------------------------------------------- analytics
  group('Paywall analytics: source + screen', () {
    testWidgets('shown, plan_selected and dismissed all carry both', (t) async {
      phone(t);
      Get.put<SubscriptionController>(_Sub());
      await t.pumpWidget(
        GetMaterialApp(
          home: TextButton(
            onPressed: () =>
                PaywallTriggers.show(PaywallTrigger.crown, screen: 'my_cards'),
            child: const Text('crown'),
          ),
        ),
      );
      await t.tap(find.text('crown'));
      await t.pumpAndSettle();
      await t.tap(find.text('Continue')); // buy
      await t.pump();
      await t.pumpAndSettle();
      Get.closeAllSnackbars();
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.close_rounded));
      await t.pumpAndSettle();

      for (final name in [
        'paywall_shown',
        'plan_selected',
        'paywall_dismissed',
      ]) {
        final e = events.where((e) => e.$1 == name).toList();
        expect(e, isNotEmpty, reason: name);
        expect(e.first.$2['source'], 'crown', reason: name);
        expect(e.first.$2['screen'], 'my_cards', reason: name);
        expect(e.first.$2['subscription_status'], isNotNull, reason: name);
      }
      // Once it is closed, later events do not inherit the screen.
      AnalyticsService.logPaywallRestoreTapped('settings');
      expect(events.last.$2.containsKey('screen'), isFalse);
    });

    testWidgets('the Expert panel Pro sheet fires the same events', (t) async {
      phone(t);
      Get.put<SubscriptionController>(_Sub());
      await t.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (c) => TextButton(
              onPressed: () => showClixaUpgrade(c),
              child: const Text('expert'),
            ),
          ),
        ),
      );
      await t.tap(find.text('expert'));
      await t.pumpAndSettle();
      await t.tap(find.text('Continue'));
      await t.pump();
      await t.pumpAndSettle();
      Get.closeAllSnackbars();
      await t.pump(const Duration(seconds: 6));
      await t.tapAt(const Offset(195, 20)); // outside the sheet
      await t.pumpAndSettle();
      for (final name in [
        'paywall_shown',
        'plan_selected',
        'paywall_dismissed',
      ]) {
        final e = events.where((e) => e.$1 == name).toList();
        expect(e, isNotEmpty, reason: name);
        expect(e.first.$2['source'], 'expert_panel', reason: name);
        expect(e.first.$2['screen'], 'clixa', reason: name);
      }
    });

    testWidgets('a paywall opened without a screen says "unknown"', (t) async {
      phone(t);
      Get.put<SubscriptionController>(_Sub());
      await t.pumpWidget(
        GetMaterialApp(
          home: TextButton(
            onPressed: () => openPaywall(source: 'x', plans: true),
            child: const Text('go'),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(
        events.firstWhere((e) => e.$1 == 'paywall_shown').$2['screen'],
        'unknown',
      );
    });

    test('every call site names its screen', () {
      final bad = <String>[];
      for (final f
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        if (f.path.contains('/paywall/services/')) continue;
        final src = f.readAsStringSync();
        for (final m in RegExp(
          r'(PaywallTriggers\.show|FreeLimits\.ensure(?:Template)?|openProPaywall)\(([^;]*?)\)\s*[;)\n,]',
          dotAll: true,
        ).allMatches(src)) {
          if (!m.group(2)!.contains('screen:')) {
            bad.add('${f.path}: ${m.group(0)!.split('\n').first}');
          }
        }
      }
      expect(bad, isEmpty);
    });
  });

  // 6 ------------------------------------------------------ share w/o card
  group('First card: Share Your Card without a saved card', () {
    Future<void> pump(WidgetTester t) async {
      phone(t);
      GetStorage().write('cro_onboarding_variant', 'control');
      Get.put<SubscriptionController>(_Sub());
      await t.pumpWidget(
        GetMaterialApp(
          home: const FirstCardReadyView(),
          getPages: [
            GetPage(
              name: Routes.MAIN,
              page: () => const Scaffold(body: Text('HOME')),
            ),
          ],
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
    }

    testWidgets(
      'no saved card: dimmed, and says why instead of doing nothing',
      (t) async {
        MainNavController.pendingFirstCardAction = null;
        await pump(t);
        final opacity = t.widget<Opacity>(
          find
              .ancestor(
                of: find.text('Share Your Card'),
                matching: find.byType(Opacity),
              )
              .first,
        );
        expect(opacity.opacity, lessThan(1));

        await t.tap(find.text('Share Your Card'));
        await t.pump(const Duration(milliseconds: 400));
        expect(
          find.text('Your card is still being saved. Try again in a moment.'),
          findsOneWidget,
        );
        expect(find.text('HOME'), findsNothing); // stayed on the screen
        expect(MainNavController.pendingFirstCardAction, isNull);

        // Scan a Card is not affected.
        Get.closeAllSnackbars();
        await t.pump(const Duration(seconds: 6));
        await t.tap(find.text('Scan a Card'));
        await t.pumpAndSettle();
        expect(find.text('HOME'), findsOneWidget);
      },
    );

    testWidgets('once the card is saved the button works', (t) async {
      MainNavController.pendingFirstCardAction = null;
      final svc = Get.put(RecentDesignsService());
      await pump(t);
      expect(
        t
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.text('Share Your Card'),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        lessThan(1),
      );
      svc.designs.add(
        RecentDesign(
          id: '1',
          path: 'x.png',
          savedAt: DateTime(2025),
          title: 'c',
          designData: const {},
        ),
      );
      await t.pump();
      expect(
        t
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.text('Share Your Card'),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        1,
      );
      await t.tap(find.text('Share Your Card'));
      await t.pumpAndSettle();
      expect(MainNavController.pendingFirstCardAction, FirstCardNext.share);
    });
  });
}
