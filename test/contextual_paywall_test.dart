import 'dart:async';
import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/analytics_service.dart';
import 'package:ai_business_card_maker/app/modules/clixa/widgets/clixa_sheets.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/cro_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/free_limits.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/paywall_triggers.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/usage_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_screen.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
import 'package:ai_business_card_maker/app/modules/paywall/widgets/pro_dialogs.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'test_fonts.dart';

/// A store with chosen products; buy / restore answer as told.
class _Sub extends SubscriptionController {
  _Sub({this.catalog = const {}});
  final Map<String, StoreProduct> catalog;
  bool buyResult = true;
  bool restoreResult = true;
  bool restoredInstead = false;

  @override
  void onInit() {}

  @override
  StoreProduct? productFor(String id) => catalog[id];

  @override
  Future<bool> buy(
    BuildContext context, {
    required String productId,
    required String plan,
    required String source,
  }) async {
    lastBuyWasRestore = restoredInstead;
    if (buyResult) isUserPro.value = true;
    return buyResult;
  }

  @override
  Future<bool> restorePurchase(
    BuildContext context, {
    required String source,
  }) async {
    if (restoreResult) {
      isUserPro.value = true;
    } else {
      unawaited(showNothingToRestoreDialog()); // as the real controller does
    }
    return restoreResult;
  }
}

StoreProduct _p(String id, double price, String text) =>
    StoreProduct(id, 'd', id, price, text, 'USD');


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Sub sub;
  late List<(String, Map<String, Object>)> events;

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
    resetProDialogGuard();
    await GetStorage().erase();
    events = [];
    AnalyticsService.sink = (n, p) => events.add((n, p));
    sub = _Sub();
    Get.put<SubscriptionController>(sub);
    Get.put(ProfileStore());
  });
  tearDown(() => AnalyticsService.sink = null);

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  /// A screen with one button that runs [action].
  Future<void> host(WidgetTester t, Future<void> Function() action) async {
    phone(t);
    await t.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(onPressed: action, child: const Text('go')),
          ),
        ),
        getPages: [
          GetPage(name: Routes.PAYWALL, page: () => const PaywallView()),
        ],
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  UsageService usage({bool pro = false}) {
    final u = UsageService(isPro: () => pro);
    Get.put(u);
    return u;
  }

  // ------------------------------------------------------------ headlines
  group('Headlines follow the source', () {
    const triggers = {
      PaywallTrigger.onboarding: 'Create and scan without limits',
      PaywallTrigger.crown: 'Create and scan without limits',
      PaywallTrigger.settings: 'Create and scan without limits',
      PaywallTrigger.scanWarning: 'Keep scanning with Pro',
      PaywallTrigger.scanLimit: 'Keep scanning with Pro',
      PaywallTrigger.aiLimit: 'Keep creating with AI',
      PaywallTrigger.proTemplate: 'Unlock every template',
      PaywallTrigger.proQr: 'Unlock every QR style',
      PaywallTrigger.watermark: 'Export without the watermark',
      PaywallTrigger.clixaLimit: 'Keep talking to your AI coach',
    };
    for (final e in triggers.entries) {
      testWidgets('${e.key.source}: "${e.value}"', (t) async {
        await host(t, () => PaywallTriggers.show(e.key, screen: 'test'));
        expect(find.text(e.value), findsOneWidget);
        expect(
          events.firstWhere((x) => x.$1 == 'paywall_shown').$2['source'],
          e.key.source,
        );
        // Not the generic one for a feature-specific source.
        if (e.value != 'Create and scan without limits') {
          expect(find.text('Create and scan without limits'), findsNothing);
        }
      });
    }

    for (final src in [
      'career_builder',
      'career_optimizer',
      'career_fix_all',
      'career_fix_locked',
      'career_rewrite',
    ]) {
      testWidgets('Career Studio ($src): "Get found by the right people"', (
        t,
      ) async {
        await host(
          t,
          () => openPaywall(source: src, plans: true, screen: 'career_hub'),
        );
        expect(find.byType(PaywallView2), findsOneWidget);
        expect(find.text('Get found by the right people'), findsOneWidget);
      });
    }

    testWidgets('Expert Panel: "Pitch to your AI expert panel"', (t) async {
      phone(t);
      await t.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (c) => TextButton(
              onPressed: () => showClixaUpgrade(c),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(find.text('Pitch to your AI expert panel'), findsOneWidget);
    });

    test('Tools-led test headline exists (no trigger uses it yet)', () {
      expect(
        const CroMessages().text('tools_headline'),
        'Grow your business with Pro',
      );
    });

    test('every feature trigger has its own headline key', () {
      final keys = PaywallTrigger.values
          .map((t) => t.headline)
          .whereType<String>()
          .toList();
      // No two features share one - except the scan warning, which is the
      // scan limit's lead-in and uses its headline.
      expect(keys.toSet().length, keys.length - 1);
      expect(PaywallTrigger.scanWarning.headline, PaywallTrigger.scanLimit.headline);
      for (final k in keys) {
        expect(CroMessages.defaults.containsKey(k), isTrue, reason: k);
      }
    });
  });

  // -------------------------------------------------------------- dialogs
  group('1 free scan left', () {
    Future<void> run(WidgetTester t) async {
      final u = usage();
      for (var i = 0; i < 4; i++) {
        u.consume(UsageFeature.scan, dedupeKey: 's$i');
      }
      await host(t, () => FreeLimits.promptScanWarning(screen: 'scan'));
    }

    testWidgets('texts and buttons match', (t) async {
      await run(t);
      expect(find.text('1 free scan left'), findsOneWidget);
      expect(
        find.text('You have used 4 of 5 free scans. Pro removes the limit.'),
        findsOneWidget,
      );
      expect(find.text('See Pro'), findsOneWidget);
      expect(find.text('Keep scanning'), findsOneWidget);
    });

    testWidgets('Keep scanning: just closes, no paywall', (t) async {
      await run(t);
      await t.tap(find.text('Keep scanning'));
      await t.pumpAndSettle();
      expect(find.text('1 free scan left'), findsNothing);
      expect(events.where((e) => e.$1 == 'paywall_shown'), isEmpty);
    });

    testWidgets('See Pro: opens the scan_warning paywall', (t) async {
      await run(t);
      await t.tap(find.text('See Pro'));
      await t.pumpAndSettle();
      expect(find.byType(PaywallView2), findsOneWidget); // Paywall 2
      expect(find.byType(PaywallView), findsNothing);
      expect(find.text('Keep scanning with Pro'), findsOneWidget);
      expect(
        events.firstWhere((e) => e.$1 == 'paywall_shown').$2['source'],
        'scan_warning',
      );
    });
  });

  group('AI limit', () {
    Future<UsageService> spent() async {
      final u = usage();
      for (var i = 0; i < 3; i++) {
        u.consume(UsageFeature.aiCard, dedupeKey: 'a$i');
      }
      return u;
    }

    testWidgets(
      'texts and buttons; Not now keeps everything and opens nothing',
      (t) async {
        await spent();
        bool? allowed;
        await host(
          t,
          () async => allowed = await FreeLimits.ensure(
            UsageFeature.aiCard,
            screen: 'ai_card_generator',
          ),
        );
        expect(find.text('You have used your free AI cards'), findsOneWidget);
        expect(
          find.text(
            'Pro gives you unlimited AI cards. Your drafts stay saved.',
          ),
          findsOneWidget,
        );
        expect(find.text('See Pro'), findsOneWidget);
        await t.tap(find.text('Not now'));
        await t.pumpAndSettle();
        expect(allowed, isFalse);
        expect(events.where((e) => e.$1 == 'paywall_shown'), isEmpty);
      },
    );

    testWidgets('See Pro opens the ai_limit paywall (Paywall 2, own headline)', (
      t,
    ) async {
      await spent();
      await host(
        t,
        () =>
            FreeLimits.ensure(UsageFeature.aiCard, screen: 'ai_card_generator'),
      );
      await t.tap(find.text('See Pro'));
      await t.pumpAndSettle();
      expect(find.byType(PaywallView2), findsOneWidget);
      expect(find.byType(PaywallView), findsNothing);
      expect(find.text('Keep creating with AI'), findsOneWidget);
      expect(
        events.firstWhere((e) => e.$1 == 'paywall_shown').$2['source'],
        'ai_limit',
      );
    });

    testWidgets('after the last free card: the same dialog', (t) async {
      await spent();
      await host(t, () => FreeLimits.promptAiLimit(screen: 'home'));
      expect(find.text('You have used your free AI cards'), findsOneWidget);
    });

    testWidgets('a free user with cards left sees no dialog; Pro never does', (
      t,
    ) async {
      final u = usage();
      u.consume(UsageFeature.aiCard, dedupeKey: 'only');
      bool? ok;
      await host(
        t,
        () async => ok = await FreeLimits.ensure(UsageFeature.aiCard),
      );
      expect(ok, isTrue);
      expect(find.text('You have used your free AI cards'), findsNothing);
    });
  });

  for (final c in [
    (
      'Locked QR style',
      PaywallTrigger.proQr,
      'This QR style is Pro',
      'Classic stays free. Pro unlocks every QR style, plus unlimited scans and AI cards.',
      'Unlock Pro',
      'Maybe later',
      'Unlock every QR style',
    ),
    (
      'Locked template',
      PaywallTrigger.proTemplate,
      'This template is Pro',
      'Unlock every template, plus unlimited scans and AI cards.',
      'Unlock Pro',
      'Maybe later',
      'Unlock every template',
    ),
  ]) {
    group(c.$1, () {
      Future<void> run(
        WidgetTester t, {
        bool pro = false,
        void Function(bool)? out,
      }) async {
        sub.isUserPro.value = pro;
        await host(t, () async {
          final r = await FreeLimits.ensureTemplate(
            isPremium: true,
            trigger: c.$2,
            screen: 'x',
          );
          out?.call(r);
        });
      }

      testWidgets('texts and buttons match', (t) async {
        await run(t);
        expect(find.text(c.$3), findsOneWidget);
        expect(find.text(c.$4), findsOneWidget);
        expect(find.text(c.$5), findsOneWidget);
        expect(find.text(c.$6), findsOneWidget);
      });

      testWidgets('Maybe later: nothing is lost, no paywall', (t) async {
        bool? r;
        await run(t, out: (v) => r = v);
        await t.tap(find.text(c.$6));
        await t.pumpAndSettle();
        expect(r, isFalse);
        expect(events.where((e) => e.$1 == 'paywall_shown'), isEmpty);
      });

      testWidgets(
        'Unlock Pro: Paywall View 2 with the trigger tag and headline',
        (t) async {
          await run(t);
          await t.tap(find.text(c.$5));
          await t.pumpAndSettle();
          expect(find.byType(PaywallView2), findsOneWidget);
          expect(find.text(c.$7), findsOneWidget);
          expect(
            events.firstWhere((e) => e.$1 == 'paywall_shown').$2['source'],
            c.$2.source,
          );
        },
      );

      testWidgets('Pro users never see it', (t) async {
        bool? r;
        await run(t, pro: true, out: (v) => r = v);
        expect(r, isTrue);
        expect(find.text(c.$3), findsNothing);
      });
    });
  }

  testWidgets('only one contextual dialog at a time', (t) async {
    await host(t, () async {
      unawaited(showAiLimitDialog());
      unawaited(showAiLimitDialog());
      unawaited(showLockedQrDialog());
    });
    expect(find.text('You have used your free AI cards'), findsOneWidget);
    expect(find.text('This QR style is Pro'), findsNothing);
  });


  // ---------------------------------------------------------- Clixa limit
  group('Clixa chat limit', () {
    testWidgets('texts and the three buttons', (t) async {
      var saved = 0;
      await host(t, () async {
        final c = Get.context!;
        await showDailyLimitSheet(c, onContinueSaved: () => saved++);
      });
      expect(find.text("You have used this week's free chats"), findsOneWidget);
      expect(
        find.text(
          'New chats unlock next week. You can still continue a saved chat, or go Pro for unlimited chats and the AI expert panel.',
        ),
        findsOneWidget,
      );
      expect(find.text('Get unlimited chats'), findsOneWidget);
      expect(find.text('Continue a saved chat'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      await t.tap(find.text('Continue a saved chat'));
      await t.pumpAndSettle();
      expect(saved, 1);
    });

    testWidgets('Get unlimited chats: clixa_limit paywall with its headline', (
      t,
    ) async {
      await host(
        t,
        () async => showDailyLimitSheet(Get.context!, onContinueSaved: () {}),
      );
      await t.tap(find.text('Get unlimited chats'));
      await t.pumpAndSettle();
      expect(find.text('Keep talking to your AI coach'), findsOneWidget);
      expect(
        events.firstWhere((e) => e.$1 == 'paywall_shown').$2['source'],
        'clixa_limit',
      );
    });
  });

  // ------------------------------------- purchase / trial / restore dialogs
  group('Purchase, trial and restore dialogs', () {
    Future<void> openPlans(WidgetTester t) async {
      await host(
        t,
        () => PaywallTriggers.show(PaywallTrigger.crown, screen: 'home'),
      );
      expect(find.byType(PaywallView2), findsOneWidget);
    }

    Future<void> openYearly(WidgetTester t) async {
      await openPlans(t);
      await t.tap(find.text('Yearly'));
      await t.pump();
    }

    testWidgets('eligible yearly purchase: trial started', (t) async {
      sub.yearlyTrialEligible.value = true;
      sub.yearlyTrialDays.value = 3;
      await openYearly(t);
      await t.tap(find.text('Start Free Trial'));
      await t.pumpAndSettle();
      expect(find.text('Your 3-day trial has started'), findsOneWidget);
      expect(find.text('We will remind you before it ends.'), findsOneWidget);
      await t.tap(find.text('Start creating'));
      await t.pumpAndSettle();
      expect(
        find.byType(PaywallView2),
        findsNothing,
      ); // dialog first, then the paywall closes
    });

    testWidgets('trial length comes from the store', (t) async {
      sub.yearlyTrialEligible.value = true;
      sub.yearlyTrialDays.value = 7;
      await openYearly(t);
      await t.tap(find.text('Start Free Trial'));
      await t.pumpAndSettle();
      expect(find.text('Your 7-day trial has started'), findsOneWidget);
    });

    testWidgets('yearly without a trial: Welcome to Pro', (t) async {
      await openYearly(t);
      await t.tap(find.text('Start Free Trial'));
      await t.pumpAndSettle();
      expect(find.text('Welcome to Pro'), findsOneWidget);
      expect(find.text('Everything is unlocked.'), findsOneWidget);
      expect(find.textContaining('trial'), findsNothing);
      await t.tap(find.text('Start creating'));
      await t.pumpAndSettle();
      expect(find.byType(PaywallView2), findsNothing);
    });

    testWidgets('monthly purchase: Welcome to Pro (never a trial)', (t) async {
      sub.yearlyTrialEligible.value = true;
      await openPlans(t);
      await t.tap(find.text('Monthly'));
      await t.pump();
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(find.text('Welcome to Pro'), findsOneWidget);
      expect(find.textContaining('trial'), findsNothing);
    });

    testWidgets('an existing subscription found: Purchases restored', (
      t,
    ) async {
      sub.restoredInstead = true;
      await openPlans(t);
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(find.text('Purchases restored'), findsOneWidget);
      expect(find.text('Welcome to Pro'), findsNothing);
    });

    testWidgets(
      'cancelled / failed purchase: no success dialog, paywall stays',
      (t) async {
        sub.buyResult = false;
        await openPlans(t);
        await t.tap(find.text('Continue'));
        await t.pumpAndSettle();
        expect(find.text('Welcome to Pro'), findsNothing);
        expect(find.byType(PaywallView2), findsOneWidget);
      },
    );

    testWidgets(
      'Restore worked: Purchases restored / Your Pro access is back. / Done',
      (t) async {
        await openPlans(t);
        await t.tap(find.text('Restore Purchase'));
        await t.pumpAndSettle();
        expect(find.text('Purchases restored'), findsOneWidget);
        expect(find.text('Your Pro access is back.'), findsOneWidget);
        await t.tap(find.text('Done'));
        await t.pumpAndSettle();
        expect(find.byType(PaywallView2), findsNothing);
      },
    );

    testWidgets(
      'Restore found nothing: No purchases found / OK, paywall stays',
      (t) async {
        sub.restoreResult = false;
        await openPlans(t);
        await t.tap(find.text('Restore Purchase'));
        await t.pumpAndSettle();
        expect(find.text('No purchases found'), findsOneWidget);
        expect(
          find.text(
            'We could not find an active subscription for this account.',
          ),
          findsOneWidget,
        );
        await t.tap(find.text('OK'));
        await t.pumpAndSettle();
        expect(find.byType(PaywallView2), findsOneWidget);
      },
    );

    testWidgets('dialogs do not overflow on a small phone', (t) async {
      t.view.physicalSize = const Size(320 * 2, 568 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: () => showAiLimitDialog(),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });
}
