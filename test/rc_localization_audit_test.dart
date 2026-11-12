import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:ai_business_card_maker/app/core/translations/app_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/app_languages.dart';
import 'package:ai_business_card_maker/app/core/utils/localized_text.dart';
import 'package:ai_business_card_maker/app/modules/onboarding/models/onboarding_config.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/cro_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/paywall_config_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}
}

/// `{"default": "D:<id>", "fr": "FR:<id>", "de": "DE:<id>"}`
Map<String, String> _t(String id) => {
  'default': 'D:$id',
  'fr': 'FR:$id',
  'de': 'DE:$id',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('aud').path,
        );
    await GetStorage.init();
  });

  setUp(() {
    Get.reset();
    // A real trial, so the "Start {days}-Day Free Trial" label is the one used.
    final sub = _Sub();
    sub.yearlyTrialEligible.value = true;
    Get.put<SubscriptionController>(sub);
  });

  tearDown(() async {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearLocaleTestValue();
    await AppStrings.setLanguage('en');
  });

  // Every user-facing text field of paywall_config: its JSON path, and what the
  // app reads for it.
  final fields = <String, String Function(PaywallConfig c)>{
    'trial.button_label': (c) => c.trialButtonLabel,
    'trial.benefit_text': (c) => c.trialBenefitText,
    'trial.info_line_1': (c) => c.trialInfoLine1,
    'trial.info_line_2': (c) => c.trialInfoLine2,
    'trial.fine_print': (c) => c.s2FinePrint(yearlySelected: true),
    'screen1.title_line1': (c) => c.s1TitleLine1,
    'screen1.title_line2': (c) => c.s1TitleLine2,
    'screen1.subtitle': (c) => c.s1Subtitle,
    'screen1.plan_title': (c) => c.s1PlanTitle,
    'screen1.save_badge': (c) => c.s1SaveBadge,
    'screen1.price_note': (c) => c.s1PriceNote,
    'screen2.title': (c) => c.s2Title,
    'screen2.subtitle': (c) => c.s2Subtitle,
    'screen2.button_label': (c) => c.s2CtaFor(yearlySelected: false),
    'screen2.trial_button_label': (c) => c.s2CtaFor(yearlySelected: true),
    'screen2.commitment_text': (c) => c.s2CommitmentText,
    'plans.monthly.title': (c) => c.monthly.title,
    'plans.monthly.period': (c) => c.monthly.period,
    'plans.monthly.description': (c) => c.monthly.description,
    'plans.yearly.title': (c) => c.yearly.title,
    'plans.yearly.badge': (c) => c.yearly.badge,
    'plans.yearly.period': (c) => c.yearly.period,
    'plans.yearly.original_price': (c) => c.yearly.originalPrice,
    'plans.yearly.save_badge': (c) => c.yearly.saveBadge,
    'plans.yearly.per_month_note': (c) => c.yearly.perMonthNote,
    'footer.restore': (c) => c.restoreLabel,
    'footer.terms': (c) => c.termsLabel,
    'footer.privacy': (c) => c.privacyLabel,
  };

  Map<String, dynamic> nest(String path, Object value) {
    final parts = path.split('.');
    Object cur = value;
    for (final p in parts.reversed) {
      cur = {p: cur};
    }
    return cur as Map<String, dynamic>;
  }

  Map<String, dynamic> merge(Map<String, dynamic> a, Map<String, dynamic> b) {
    final out = Map<String, dynamic>.of(a);
    b.forEach((k, v) {
      out[k] = v is Map<String, dynamic> && out[k] is Map<String, dynamic>
          ? merge(out[k] as Map<String, dynamic>, v)
          : v;
    });
    return out;
  }

  group('paywall_config: EVERY text field takes a text per language', () {
    for (final e in fields.entries) {
      test(e.key, () async {
        final json = nest(e.key, _t(e.key));
        final c = PaywallConfig.fromJsonString(_encode(json));
        await AppStrings.setLanguage('fr');
        expect(e.value(c), contains('FR:${e.key}'), reason: 'fr');
        await AppStrings.setLanguage('de');
        expect(e.value(c), contains('DE:${e.key}'), reason: 'de');
        await AppStrings.setLanguage('ja'); // not listed: the default
        expect(e.value(c), contains('D:${e.key}'), reason: 'ja');
      });
    }

    test('trial.no_trial_button_label (no real trial in the store)', () async {
      Get.find<SubscriptionController>().yearlyTrialEligible.value = false;
      final c = PaywallConfig.fromJsonString(
        _encode(nest('trial.no_trial_button_label', _t('nt'))),
      );
      await AppStrings.setLanguage('fr');
      expect(c.trialButtonLabel, 'FR:nt');
      await AppStrings.setLanguage('ja');
      expect(c.trialButtonLabel, 'D:nt');
    });

    test('feature lists (both screens) and every headline', () async {
      final heads = {
        for (final k in (PaywallConfig.defaultJson['headlines'] as Map).keys)
          k as String: _t('h.$k'),
      };
      final c = PaywallConfig.fromJsonString(_encode({
        'screen1': {
          'features': [
            {'icon': 'scan', 'text': _t('s1f0')},
            {'icon': 'ai', 'text': _t('s1f1')},
          ],
        },
        'screen2': {
          'features': [_t('s2f0'), 'plain', _t('s2f2')],
        },
        'headlines': heads,
      }));
      await AppStrings.setLanguage('fr');
      expect(c.s1Features.map((f) => f.text), ['FR:s1f0', 'FR:s1f1']);
      expect(c.s2Features, ['FR:s2f0', 'plain', 'FR:s2f2']);
      for (final k in heads.keys) {
        expect(c.headlineFor(k), 'FR:h.$k', reason: k);
      }
      await AppStrings.setLanguage('de');
      expect(c.s2Features, ['DE:s2f0', 'plain', 'DE:s2f2']);
    });

    test('a language missing from the map falls back to the built-in, '
        'translated text (never blank, never raw keys)', () async {
      final c = PaywallConfig.fromJsonString(_encode({
        'plans': {'monthly': {'title': {'fr': 'Mensuel RC'}}},
        'screen2': {'features': [{'fr': 'Only French'}]},
      }));
      await AppStrings.setLanguage('fr');
      expect(c.monthly.title, 'Mensuel RC');
      await AppStrings.setLanguage('de');
      // No de / default / en entry: the app's own German "Monthly".
      expect(c.monthly.title, isNotEmpty);
      expect(c.monthly.title, isNot('Monthly'));
      expect(c.monthly.title, isNot(contains('paywall_cfg')));
      expect(c.s2Features.first, isNot('Only French'));
      expect(c.s2Features.first, isNotEmpty);
      await AppStrings.setLanguage('en');
      expect(c.monthly.title, 'Monthly');
    });

    test('a plain changed string is still shown as written everywhere '
        '(documented behaviour)', () async {
      final c = PaywallConfig.fromJsonString(_encode({
        'plans': {'monthly': {'title': 'MONTHLYYY'}},
      }));
      for (final tag in ['en', 'fr', 'ar']) {
        await AppStrings.setLanguage(tag);
        expect(c.monthly.title, 'MONTHLYYY');
      }
    });
  });

  group('cro_messages: every text takes a text per language', () {
    test('all keys (headlines, counters, watermark texts, links)', () async {
      final json = _encode({
        for (final k in CroMessages.defaults.keys) k: _t(k),
      });
      final m = CroMessages.fromJsonString(json);
      await AppStrings.setLanguage('fr');
      for (final k in CroMessages.defaults.keys) {
        expect(m.text(k), 'FR:$k', reason: k);
        expect(m.overridden(k), isTrue, reason: k);
      }
      await AppStrings.setLanguage('ja');
      expect(m.text('watermark_text'), 'D:watermark_text');
    });

    test('a language missing from the map: the built-in (translated) text',
        () async {
      final m = CroMessages.fromJsonString(_encode({
        'counter_scans': {'fr': '{used} sur {limit}'},
      }));
      await AppStrings.setLanguage('de');
      expect(m.overridden('counter_scans'), isFalse); // -> cro_msg_counter_scans.tr
    });
  });

  group('onboarding_config: every text takes a text per language', () {
    test('title, subtitle and button', () async {
      final o = OnboardingConfig.fromJsonString(_encode({
        'title': _t('t'),
        'subtitle': _t('s'),
        'button_text': _t('b'),
      }));
      await AppStrings.setLanguage('fr');
      expect([o.title, o.subtitle, o.buttonText], ['FR:t', 'FR:s', 'FR:b']);
      await AppStrings.setLanguage('ja');
      expect([o.title, o.subtitle, o.buttonText], ['D:t', 'D:s', 'D:b']);
    });

    test('a language missing everywhere: the built-in translated text',
        () async {
      final o = OnboardingConfig.fromJsonString(_encode({
        'title': {'fr': 'X'},
        'button_text': {'fr': 'Y'},
      }));
      await AppStrings.setLanguage('de');
      expect(o.title, isNot('X'));
      expect(o.title, isNotEmpty);
      expect(o.buttonText, isNot('Y'));
    });
  });

  group('language switching', () {
    test('every shipped language tag picks its own text', () async {
      final map = {'default': 'DEF', for (final t in kLanguageAssets.keys) t: 'T:$t'};
      for (final tag in kLanguageAssets.keys) {
        await AppStrings.setLanguage(tag);
        expect(pickLocalized(map), 'T:$tag', reason: tag);
      }
    });

    test('a region tag falls back to the language code, then default', () async {
      await AppStrings.setLanguage('zh-TW');
      expect(pickLocalized({'zh': 'ZH', 'default': 'D'}), 'ZH');
      expect(pickLocalized({'zh-TW': 'TW', 'zh': 'ZH'}), 'TW');
      expect(pickLocalized({'default': 'D'}), 'D');
      expect(pickLocalized({'en': 'E'}), 'E');
      expect(pickLocalized({'fr': 'F'}), isNull);
    });

    test('changing the app language, then the phone language (System '
        'default), switches the text each time', () async {
      final c = PaywallConfig.fromJsonString(_encode({
        'plans': {'monthly': {'title': _t('m')}},
      }));
      final binding = TestWidgetsFlutterBinding.instance;
      await AppStrings.setLanguage('fr');
      expect(c.monthly.title, 'FR:m');
      await AppStrings.setLanguage('de');
      expect(c.monthly.title, 'DE:m');

      AppStrings.followDeviceLanguage();
      await AppStrings.useSystemDefault();
      binding.platformDispatcher.localeTestValue = const Locale('fr', 'FR');
      binding.handleLocaleChanged();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(c.monthly.title, 'FR:m');
      binding.platformDispatcher.localeTestValue = const Locale('de', 'DE');
      binding.handleLocaleChanged();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(c.monthly.title, 'DE:m');
    });
  });

  test('the paste files only use fields the app localizes (no stray English '
      'text field)', () {
    // Every text path of the default config is covered above.
    final covered = {...fields.keys, 'trial.no_trial_button_label'};
    final textPaths = <String>{};
    void walk(Object? v, String path) {
      if (v is Map) {
        v.forEach((k, x) => walk(x, path.isEmpty ? '$k' : '$path.$k'));
      } else if (v is String) {
        textPaths.add(path);
      }
    }
    walk(PaywallConfig.defaultJson, '');
    final notText = {
      'plans.monthly.price', // prices come from the store
      'plans.yearly.price',
    };
    final skipped = textPaths.where((p) =>
        !covered.contains(p) &&
        !notText.contains(p) &&
        !p.startsWith('headlines.') &&
        !p.startsWith('screen1.features') &&
        !p.startsWith('screen2.features') &&
        !p.endsWith('.icon'));
    expect(skipped, isEmpty, reason: 'text fields not covered: $skipped');
  });
}

String _encode(Object o) => jsonEncode(o);
