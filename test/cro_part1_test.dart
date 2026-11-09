import 'dart:io';
import 'dart:math';

import 'package:ai_business_card_maker/app/core/services/analytics_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/cro_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/offer_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/onboarding_experiment.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/usage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<(String, Map<String, Object>)> events;
  var now = DateTime(2026, 1, 1, 9);
  var pro = false;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('cro').path,
        );
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
    now = DateTime(2026, 1, 1, 9);
    pro = false;
    events = [];
    AnalyticsService.sink = (n, p) => events.add((n, p));
  });
  tearDown(() => AnalyticsService.sink = null);

  UsageService usage() => UsageService(
    clock: () => now,
    isPro: () => pro,
    limits: () => const CroLimits(),
  );

  group('config', () {
    test('defaults are the plan\'s Option A', () {
      const l = CroLimits();
      expect(
        [
          l.scanFree,
          l.aiCardFree,
          l.templatesFree,
          l.bgRemoverFree,
          l.clixaChatsPerWeek,
          l.careerBuildLifetime,
          l.careerOptimizeLifetime,
        ],
        [5, 3, 10, 1, 3, 1, 1],
      );
      expect(l.scanWarningRemaining, 1);
    });

    test('bad / empty / partial JSON falls back to the defaults', () {
      expect(CroLimits.fromJsonString('').scanFree, 5);
      expect(CroLimits.fromJsonString('not json').aiCardFree, 3);
      expect(CroLimits.fromJsonString('{"scan_free": 7}').scanFree, 7);
      expect(CroLimits.fromJsonString('{"scan_free": 7}').aiCardFree, 3);
      expect(CroLimits.fromJsonString('{"scan_free": "x"}').scanFree, 5);
    });

    test('triggers can be switched off one by one', () {
      final t = CroTriggers.fromJsonString('{"watermark": {"enabled": false}}');
      expect(t.enabled('watermark'), isFalse);
      expect(t.enabled('crown'), isTrue);
    });

    test('messages: default, remote override', () {
      expect(const CroMessages().overridden('watermark_link'), isFalse);
      final m = CroMessages.fromJsonString('{"watermark_link": "Go clean"}');
      expect(m.overridden('watermark_link'), isTrue);
      expect(m.text('watermark_link'), 'Go clean');
    });

    test('experiment and offers parse with defaults', () {
      expect(CroExperiment.fromJsonString('').paywallPercent, 50);
      final o = CroOffers.fromJsonString('{"first_year_product_id": "x"}');
      expect(o.firstYearProductId, 'x');
      expect(o.maxPerDay, 1);
    });
  });

  group('UsageService', () {
    test('counts, stops at the limit, never goes over', () {
      final u = usage();
      for (var i = 0; i < 5; i++) {
        expect(u.consume(UsageFeature.scan, dedupeKey: 's$i'), isTrue);
      }
      expect(u.remaining(UsageFeature.scan), 0);
      expect(u.canUse(UsageFeature.scan), isFalse);
      expect(u.consume(UsageFeature.scan, dedupeKey: 'extra'), isFalse);
      expect(u.used(UsageFeature.scan), 5);
    });

    test('the same dedupe key is never counted twice', () {
      final u = usage();
      u.consume(UsageFeature.aiCard, dedupeKey: 'a');
      u.consume(UsageFeature.aiCard, dedupeKey: 'a');
      expect(u.used(UsageFeature.aiCard), 1);
    });

    test('Pro is not limited and not counted', () {
      pro = true;
      final u = usage();
      for (var i = 0; i < 20; i++) {
        expect(u.consume(UsageFeature.scan), isTrue);
      }
      expect(u.used(UsageFeature.scan), 0);
      expect(u.canUse(UsageFeature.scan), isTrue);
    });

    test('Clixa resets after 7 days, the others are lifetime', () {
      final u = usage();
      for (var i = 0; i < 3; i++) {
        u.consume(UsageFeature.clixaChat, dedupeKey: 'c$i');
      }
      u.consume(UsageFeature.careerBuild, dedupeKey: 'b');
      expect(u.canUse(UsageFeature.clixaChat), isFalse);

      now = now.add(const Duration(days: 6, hours: 23));
      expect(u.canUse(UsageFeature.clixaChat), isFalse);

      now = now.add(const Duration(hours: 2));
      expect(u.remaining(UsageFeature.clixaChat), 3);
      expect(u.canUse(UsageFeature.careerBuild), isFalse); // lifetime
    });

    test('survives a restart (stored on the device)', () {
      usage().consume(UsageFeature.bgRemover, dedupeKey: 'x');
      expect(usage().canUse(UsageFeature.bgRemover), isFalse);
    });

    test('analytics: consumed + limit reached, with consistent params', () {
      final u = usage();
      u.consume(UsageFeature.bgRemover, dedupeKey: 'x', source: 'logo_bg');
      final names = events.map((e) => e.$1).toList();
      expect(names, contains('usage_consumed'));
      expect(names, contains('limit_reached'));
      expect(events.first.$2['subscription_status'], isNotNull);
    });
  });

  group('OfferService', () {
    OfferService svc({String product = 'disc', bool has = true}) =>
        OfferService(
          clock: () => now,
          isPro: () => pro,
          config: () => CroOffers(firstYearProductId: product),
          hasProduct: (_) => has,
        )..onInit();

    test('no product configured or returned by the store: no offer', () {
      expect(svc(product: '').canShowFirstYear(), isFalse);
      expect(svc(has: false).canShowFirstYear(), isFalse);
    });

    test('first-year offer: once ever, once per day, never to Pro', () {
      var s = svc();
      expect(s.canShowFirstYear(), isTrue);
      s.markShown(OfferType.firstYear);
      s = svc();
      expect(s.canShowFirstYear(), isFalse);
      pro = true;
      expect(svc().canShowFirstYear(), isFalse);
    });

    test('returning offer only on day 2-3, after a dismissed paywall', () {
      final s = svc();
      s.onPaywallDismissed();
      expect(s.canShowReturning(), isFalse); // day 1
      now = now.add(const Duration(days: 1));
      expect(s.canShowReturning(), isTrue); // day 2
      now = now.add(const Duration(days: 2));
      expect(s.canShowReturning(), isFalse); // day 4
    });

    test('max one offer per day', () {
      final s = svc();
      s.onPaywallDismissed();
      now = now.add(const Duration(days: 1));
      s.markShown(OfferType.firstYear);
      expect(s.canShowReturning(), isFalse); // same day
    });
  });

  group('Onboarding experiment', () {
    OnboardingExperiment exp(int percent, int seed, {bool enabled = true}) =>
        OnboardingExperiment(
          config: () =>
              CroExperiment(enabled: enabled, paywallPercent: percent),
          random: Random(seed),
          isPro: () => pro,
        );

    test('the group is kept once assigned', () {
      final first = exp(50, 1).variant();
      for (var i = 0; i < 10; i++) {
        expect(exp(50, i).variant(), first);
      }
      expect(events.where((e) => e.$1 == 'experiment_assigned').length, 1);
    });

    test('0% = control, 100% = paywall, test off = everyone sees it', () async {
      expect(exp(0, 3).variant(), OnboardingExperiment.controlGroup);
      await GetStorage().erase();
      expect(exp(100, 3).variant(), OnboardingExperiment.paywallGroup);
      await GetStorage().erase();
      expect(
        exp(0, 3, enabled: false).variant(),
        OnboardingExperiment.paywallGroup,
      );
    });
  });
}
