import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:ai_business_card_maker/app/core/translations/app_strings.dart';
import 'package:ai_business_card_maker/app/modules/onboarding/models/onboarding_config.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/cro_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/paywall_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/revenue_cat_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/usage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

String _paste(String key, {String platform = 'android'}) =>
    File('docs/remote_config/$key.$platform.json').readAsStringSync();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('rcn').path,
        );
    await GetStorage.init();
  });

  group('plan_limits', () {
    for (final platform in ['android', 'ios']) {
      test('the $platform paste file gives the plan\'s limits', () {
        final l = CroLimits.fromPlanLimitsString(
          _paste('plan_limits', platform: platform),
        )!;
        expect(
          [
            l.scanFree,
            l.scanWarningRemaining,
            l.aiCardFree,
            l.clixaChatsPerWeek,
            l.careerBuildLifetime,
            l.careerOptimizeLifetime,
          ],
          [5, 1, 3, 3, 1, 1],
        );
        expect(l.clixaChatsPerWeekPro, 5);
        expect(l.showCounters, isTrue);
      });
    }

    test('no weekly entry anywhere, but a weekly tier gets the paid allowance',
        () {
      final raw = _paste('plan_limits');
      expect(jsonDecode(raw)['plans'].containsKey('weekly'), isFalse);
      // A weekly subscriber is Pro (isPro) and reads the same paid allowance.
      expect(CroLimits.fromPlanLimitsString(raw)!.clixaChatsPerWeekPro, 5);
    });

    test('-1 on every paid tier is unlimited; bad JSON falls back', () {
      final raw = jsonEncode({
        'plans': {
          'free': {'clixa_chats': {'limit': 3}},
          'yearly': {'clixa_chats': {'limit': -1}},
        },
      });
      expect(CroLimits.fromPlanLimitsString(raw)!.clixaChatsPerWeekPro, -1);
      expect(CroLimits.fromPlanLimitsString('nope'), isNull);
      expect(CroLimits.fromPlanLimitsString('{}'), isNull);
      expect(const CroLimits().clixaChatsPerWeekPro, 5); // built-in default
    });

    test('Pro Clixa chats are counted and stop at 5; other features stay free',
        () async {
      await GetStorage().erase();
      final u = UsageService(
        isPro: () => true,
        limits: () => const CroLimits(clixaChatsPerWeekPro: 5),
      );
      for (var i = 0; i < 5; i++) {
        expect(u.canUse(UsageFeature.clixaChat), isTrue);
        expect(u.consume(UsageFeature.clixaChat, dedupeKey: 'c$i'), isTrue);
      }
      expect(u.canUse(UsageFeature.clixaChat), isFalse);
      expect(u.consume(UsageFeature.clixaChat, dedupeKey: 'c6'), isFalse);
      expect(u.unlimitedForPro(UsageFeature.clixaChat), isFalse);
      // Scans stay unlimited and uncounted for Pro.
      expect(u.canUse(UsageFeature.scan), isTrue);
      expect(u.consume(UsageFeature.scan, dedupeKey: 's'), isTrue);
      expect(u.used(UsageFeature.scan), 0);
    });

    test('Pro with -1 stays unlimited and uncounted (as before)', () async {
      await GetStorage().erase();
      final u = UsageService(
        isPro: () => true,
        limits: () => const CroLimits(clixaChatsPerWeekPro: -1),
      );
      expect(u.unlimitedForPro(UsageFeature.clixaChat), isTrue);
      expect(u.consume(UsageFeature.clixaChat, dedupeKey: 'x'), isTrue);
      expect(u.used(UsageFeature.clixaChat), 0);
    });

    test('free users keep the free allowance', () async {
      await GetStorage().erase();
      final u = UsageService(
        isPro: () => false,
        limits: () => const CroLimits(clixaChatsPerWeekPro: 5),
      );
      expect(u.limitOf(UsageFeature.clixaChat), 3);
    });
  });

  group('paste files match the app', () {
    test('no offers, no weekly, no image, no templates/bg-remover limits', () {
      for (final k in ['onboarding_config', 'plan_limits', 'paywall_config',
          'paywall_offers']) {
        final raw = _paste(k);
        expect(raw.contains('"weekly": {'), isFalse, reason: k); // no weekly tier
        expect(raw.contains('image'), isFalse, reason: k);
        expect(raw.contains('first_year'), isFalse, reason: k);
        expect(raw.contains('returning'), isFalse, reason: k);
        expect(raw.contains('max_dialogs'), isFalse, reason: k);
        expect(raw.contains('discount'), isFalse, reason: k);
      }
      final plans = jsonDecode(_paste('plan_limits'))['plans'] as Map;
      for (final plan in plans.values) {
        expect((plan as Map).containsKey('templates'), isFalse);
        expect(plan.containsKey('background_remover'), isFalse);
      }
      expect(_paste('cro_messages').contains('counter_bg'), isFalse);
      expect(_paste('cro_triggers').contains('pro_bg'), isFalse);
      final offers = jsonDecode(_paste('paywall_offers')) as Map;
      expect(offers.keys.toSet(), {'products', 'trial'});
    });

    test('the template keeps the conditions, descriptions and untouched keys',
        () {
      final t = jsonDecode(
        File('docs/remote_config/template_proposed.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final names = [for (final c in t['conditions']) c['name']];
      // The console's existing conditions are reused (their names end in a dot).
      expect(names, ['Android.', 'iOS.']);
      final p = t['parameters'] as Map<String, dynamic>;
      for (final k in ['onboarding_config', 'plan_limits', 'paywall_config',
          'cro_triggers', 'cro_messages', 'cro_experiment']) {
        expect(p[k]['conditionalValues'].keys, containsAll(names));
      }
      for (final e in p.entries) {
        if (e.key.endsWith('_version_config')) continue; // left as it is
        expect((e.value['description'] as String?)?.isNotEmpty, isTrue,
            reason: e.key);
      }
      expect(p.containsKey('credit_pools'), isFalse);
      expect(p.containsKey('paywall_offers'), isTrue);
      expect(p.containsKey('cro_offers'), isFalse);
      expect(p.containsKey('cro_limits'), isTrue);
      expect(p.containsKey('onboarding_enabled'), isTrue);
    });
  });

  group('paywall_offers', () {
    test('products and trial are read; nothing else exists', () {
      final o = PaywallOffers.fromJsonString(_paste('paywall_offers'));
      expect(o.yearlyProductId, 'business_card_yearly');
      expect(o.monthlyProductId, 'business_card_monthly');
      expect(o.trialEnabled, isTrue);
      expect(o.trialDays, 3);
      final none = PaywallOffers.fromJsonString('');
      expect([none.yearlyProductId, none.trialEnabled, none.trialDays],
          [null, null, null]);
    });

    test('the plans use the configured ids, else the built-in ones', () {
      // Nothing fetched in tests: the built-in ids.
      expect(RevenueCatHelper.yearlyProductId, 'business_card_yearly');
      expect(RevenueCatHelper.monthlyProductId, 'business_card_monthly');
      expect(RevenueCatHelper.weeklyProductId, 'business_card_weekly');
    });

    test('free templates are fixed in the app (not a Remote Config value)', () {
      expect(CroLimits.freeTemplates, 10);
    });
  });

  group('onboarding_config', () {
    test('the paste file keeps the built-in (translated) texts', () {
      final c = OnboardingConfig.fromJsonString(_paste('onboarding_config'));
      expect(c.enabled, isTrue);
      expect(c.title, OnboardingConfig.titleDefault);
      expect(c.buttonText, OnboardingConfig.buttonDefault);
      expect(c.subtitle, '');
    });

    test('changed text is shown as written; missing keeps old switch', () {
      final c = OnboardingConfig.fromJsonString(
        '{"title":"Hello","button_text":"Go","subtitle":" Sub "}',
      );
      expect([c.title, c.buttonText, c.subtitle], ['Hello', 'Go', 'Sub']);
      expect(c.enabled, isNull);
      expect(OnboardingConfig.fromJsonString('bad').enabled, isNull);
      expect(OnboardingConfig.fromJsonString('{"enabled":false}').enabled,
          isFalse);
    });
  });

  group('paywall_config', () {
    test('headlines: defaults defer to the translated text; changes win', () {
      final c = PaywallConfig.fromJsonString(_paste('paywall_config'));
      for (final s in ['onboarding', 'scan_warning', 'pro_qr', 'career']) {
        expect(c.headlineFor(s, generic: true), isNull, reason: s);
      }
      final o = PaywallConfig.fromJsonString(
        '{"headlines":{"pro_qr":"QR for all","default":"Everything"}}',
      );
      expect(o.headlineFor('pro_qr'), 'QR for all');
      expect(o.headlineFor('crown', generic: true), 'Everything');
      expect(o.headlineFor('scan_limit'), isNull);
    });

    test('buttons: Continue for monthly, Start Free Trial needs a real trial',
        () {
      final c = PaywallConfig.fromJsonString(_paste('paywall_config'));
      expect(c.s2CtaFor(yearlySelected: false), 'Continue');
      // Yearly selected: the button reads Start Free Trial.
      expect(c.s2CtaFor(yearlySelected: true), 'Start Free Trial');
    });
  });

  group('Remote Config text and languages', () {
    tearDown(() => AppStrings.setLanguage('en'));

    test('a plain string is shown as written, in every language', () async {
      final c = PaywallConfig.fromJsonString(
        '{"plans":{"monthly":{"title":"MONTHLYYY"}}}',
      );
      for (final tag in ['en', 'fr', 'ar']) {
        await AppStrings.setLanguage(tag);
        expect(c.monthly.title, 'MONTHLYYY', reason: tag);
      }
    });

    test('a map gives one text per language, with a default', () async {
      final c = PaywallConfig.fromJsonString(
        '{"plans":{"monthly":{"title":{"default":"MONTHLYYY","fr":"MENSUEL","pt":"MENSAL"}}}}',
      );
      await AppStrings.setLanguage('fr');
      expect(c.monthly.title, 'MENSUEL');
      await AppStrings.setLanguage('pt');
      expect(c.monthly.title, 'MENSAL');
      await AppStrings.setLanguage('de'); // not listed: the default
      expect(c.monthly.title, 'MONTHLYYY');
      await AppStrings.setLanguage('en');
      expect(c.monthly.title, 'MONTHLYYY');
    });

    test('the built-in English "Monthly" is still translated', () async {
      final c = PaywallConfig.fromJsonString(
        '{"plans":{"monthly":{"title":"Monthly"}}}',
      );
      await AppStrings.setLanguage('fr');
      expect(c.monthly.title, isNot('Monthly'));
    });

    test('headlines and onboarding texts accept the same map', () async {
      final c = PaywallConfig.fromJsonString(
        '{"headlines":{"pro_qr":{"default":"QR for all","fr":"QR pour tous"}}}',
      );
      await AppStrings.setLanguage('fr');
      expect(c.headlineFor('pro_qr'), 'QR pour tous');
      await AppStrings.setLanguage('es');
      expect(c.headlineFor('pro_qr'), 'QR for all');
      final o = OnboardingConfig.fromJsonString(
        '{"button_text":{"default":"Go","fr":"Allons-y"}}',
      );
      await AppStrings.setLanguage('fr');
      expect(o.buttonText, 'Allons-y');
    });
  });

  group('every Remote Config text follows the app language', () {
    tearDown(() async {
      TestWidgetsFlutterBinding.instance.platformDispatcher
          .clearLocaleTestValue();
      await AppStrings.useSystemDefault();
      await AppStrings.setLanguage('en');
    });

    test('feature lists, counters and watermark texts accept a map', () async {
      final c = PaywallConfig.fromJsonString(
        '{"screen2":{"features":[{"default":"A","fr":"AA"},"plain",{"default":"C"}]},'
        '"screen1":{"features":[{"icon":"scan","text":{"default":"S","fr":"SS"}}]}}',
      );
      final m = CroMessages.fromJsonString(
        '{"counter_scans":{"default":"{used}/{limit}","fr":"{used} sur {limit}"},'
        '"watermark_text":"As written"}',
      );
      await AppStrings.setLanguage('fr');
      expect(c.s2Features, ['AA', 'plain', 'C']);
      expect(c.s1Features.single.text, 'SS');
      expect(m.text('counter_scans'), '{used} sur {limit}');
      expect(m.text('watermark_text'), 'As written'); // plain: unchanged
      await AppStrings.setLanguage('en');
      expect(c.s2Features, ['A', 'plain', 'C']);
      expect(m.text('counter_scans'), '{used}/{limit}');
    });

    test('a map entry equal to the built-in English text is translated', () async {
      final m = CroMessages.fromJsonString(
        '{"watermark_link":{"default":"Remove watermark"}}',
      );
      expect(m.overridden('watermark_link'), isFalse);
    });

    test('changing the phone language switches the app while it follows the '
        'system (and a language picked in the app is kept)', () async {
      final binding = TestWidgetsFlutterBinding.instance;
      Future<void> settle() =>
          Future<void>.delayed(const Duration(milliseconds: 80));
      AppStrings.followDeviceLanguage();
      await AppStrings.useSystemDefault();
      binding.platformDispatcher.localeTestValue = const Locale('fr', 'FR');
      binding.handleLocaleChanged();
      await settle();
      expect(AppStrings.language, 'fr');
      binding.platformDispatcher.localeTestValue = const Locale('es', 'ES');
      binding.handleLocaleChanged();
      await settle();
      expect(AppStrings.language, 'es');

      // A language chosen in the app wins over the phone's.
      await AppStrings.setLanguage('de');
      binding.platformDispatcher.localeTestValue = const Locale('ja', 'JP');
      binding.handleLocaleChanged();
      await settle();
      expect(AppStrings.language, 'de');
    });
  });

  group('localization after moving paywall data to Remote Config', () {
    Map<String, dynamic> snapshot(PaywallConfig c) => {
      's2': [
        c.s2Title, c.s2Subtitle, c.s2CtaLabel, c.s2CommitmentText,
        ...c.s2Features,
      ],
      's1': [
        c.s1TitleLine1, c.s1TitleLine2, c.s1Subtitle, c.s1PlanTitle,
        for (final f in c.s1Features) f.text,
      ],
      'plans': [
        c.monthly.title, c.monthly.period, c.monthly.description,
        c.yearly.title, c.yearly.badge, c.yearly.period,
      ],
      'footer': [c.restoreLabel, c.termsLabel, c.privacyLabel],
      'trial': [
        c.trialBenefitText, c.trialInfoLine1, c.trialInfoLine2,
        c.trialButtonLabel,
      ],
    };

    test('the pasted paywall_config shows the same text as the built-in one '
        'in every language (nothing stuck in English)', () async {
      final pasted = _paste('paywall_config');
      for (final tag in AppStrings.assetByLanguage.keys) {
        await AppStrings.setLanguage(tag);
        expect(
          snapshot(PaywallConfig.fromJsonString(pasted)),
          snapshot(PaywallConfig.defaults),
          reason: tag,
        );
      }
      await AppStrings.setLanguage('en');
    });

    test('other languages really translate the paywall words', () async {
      final english = snapshot(PaywallConfig.defaults);
      for (final tag in ['fr', 'es', 'de', 'ar', 'ja', 'hi']) {
        if (!AppStrings.assetByLanguage.containsKey(tag)) continue;
        await AppStrings.setLanguage(tag);
        final c = snapshot(PaywallConfig.fromJsonString(_paste('paywall_config')));
        var same = 0, total = 0;
        for (final k in c.keys) {
          final a = c[k] as List, b = english[k] as List;
          for (var i = 0; i < a.length; i++) {
            total++;
            if (a[i] == b[i]) same++;
          }
        }
        expect(same, lessThan(total ~/ 4), reason: '$tag mostly English');
      }
      await AppStrings.setLanguage('en');
    });

    test('headlines and the new texts exist in every language file', () {
      final keys = [
        'paywall_cfg_start_free_trial', 'clixa_pro_left',
        'clixa_limit_pro_title', 'clixa_limit_pro_message',
        'cro_msg_default_headline', 'cro_msg_scan_limit_headline',
        'cro_msg_ai_limit_headline', 'cro_msg_pro_template_headline',
        'cro_msg_pro_qr_headline',
        'cro_msg_watermark_headline', 'cro_msg_clixa_limit_headline',
        'cro_msg_career_headline',
      ];
      for (final f in Directory('assets/lang').listSync().whereType<File>()) {
        final n = f.uri.pathSegments.last;
        if (n == 'add.json' || n == 'english.json') continue;
        final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final k in keys) {
          expect(d[k], isA<String>(), reason: '$n missing $k');
        }
        expect(d['clixa_pro_left'], allOf(contains('{left}'), contains('{total}')));
      }
    });
  });
}
