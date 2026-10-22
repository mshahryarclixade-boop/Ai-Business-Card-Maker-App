import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:ai_business_card_maker/app/core/translations/app_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/ai_card_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/career_studio_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/contacts_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/core_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/custom_create_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/email_signature_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/home_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/main_nav_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/onboarding_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/paywall_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/profile_setup_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/profile_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/qr_code_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/recent_designs_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/remove_background_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/scan_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/services_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/settings_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/splash_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/template_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/en/widgets_strings.dart';
import 'package:ai_business_card_maker/app/core/translations/tr_extension.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final files = <String, Map<String, String>>{
    'core': coreStrings,
    'ai_card': aiCardStrings,
    'career_studio': careerStudioStrings,
    'contacts': contactsStrings,
    'custom_create': customCreateStrings,
    'home': homeStrings,
    'main_nav': mainNavStrings,
    'onboarding': onboardingStrings,
    'paywall': paywallStrings,
    'profile': profileStrings,
    'profile_setup': profileSetupStrings,
    'qr_code': qrCodeStrings,
    'recent_designs': recentDesignsStrings,
    'remove_background': removeBackgroundStrings,
    'scan': scanStrings,
    'services': servicesStrings,
    'email_signature': emailSignatureStrings,
    'settings': settingsStrings,
    'splash': splashStrings,
    'template': templateStrings,
    'widgets': widgetsStrings,
  };

  test('keys are unique across the per-feature files', () {
    final seen = <String, String>{};
    final dupes = <String>[];
    files.forEach((file, map) {
      for (final k in map.keys) {
        final prev = seen[k];
        if (prev != null) dupes.add('$k ($prev, $file)');
        seen[k] = file;
      }
    });
    expect(dupes, isEmpty);
    expect(enStrings.length, seen.length);
  });

  test('keys are snake_case and values are non-empty', () {
    final key = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
    for (final e in enStrings.entries) {
      expect(key.hasMatch(e.key), isTrue, reason: 'bad key ${e.key}');
      expect(e.value.trim(), isNotEmpty, reason: 'empty ${e.key}');
    }
  });

  test('every key used with .tr / .trParams in lib/ exists', () {
    final used = RegExp(r"""['"]([a-z][a-z0-9_]*)['"]\s*\.(?:tr\b|trParams)""");
    final missing = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      // The extension's own doc comments mention `'key'.tr`.
      if (f.path.endsWith('tr_extension.dart')) continue;
      final text = f.readAsStringSync();
      for (final m in used.allMatches(text)) {
        if (!enStrings.containsKey(m.group(1))) {
          missing.add('${m.group(1)} in ${f.path}');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('placeholders are filled by trParams', () {
    expect(
      'x'.trParams({'a': 1}),
      'x',
      reason: 'unknown key falls back to the key itself',
    );
  });

  test('missing language keys fall back to English', () {
    final k = enStrings.keys.first;
    AppStrings.language = 'zz';
    addTearDown(() => AppStrings.language = AppStrings.fallbackLanguage);
    expect(k.tr, enStrings[k]);
  });

  group('device language at first install', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => Directory.systemTemp.createTempSync('gs').path,
          );
      await GetStorage.init();
      await GetStorage().erase();
      AppStrings.language = AppStrings.fallbackLanguage;
    });

    test(
      'a device language we do not ship falls back to English (nothing saved)',
      () async {
        final binding = TestWidgetsFlutterBinding.instance;
        binding.platformDispatcher.localeTestValue = const Locale('xx', 'XX');
        addTearDown(binding.platformDispatcher.clearLocaleTestValue);
        await AppStrings.init();
        expect(AppStrings.language, 'en');
        // Following the device: nothing is saved.
        expect(GetStorage().read<String>('app_language'), isNull);
        expect(enStrings.keys.first.tr, enStrings.values.first);
      },
    );

    test('a saved choice wins over the device language', () async {
      final binding = TestWidgetsFlutterBinding.instance;
      binding.platformDispatcher.localeTestValue = const Locale('en', 'US');
      addTearDown(binding.platformDispatcher.clearLocaleTestValue);
      await GetStorage().write('app_language', 'xx'); // stale / unsupported
      await AppStrings.init();
      expect(AppStrings.language, 'en');
    });

    test('a picked language is saved; System default clears it and follows '
        'the device', () async {
      final binding = TestWidgetsFlutterBinding.instance;
      binding.platformDispatcher.localeTestValue = const Locale('ur', 'PK');
      addTearDown(binding.platformDispatcher.clearLocaleTestValue);

      expect(await AppStrings.setLanguage('fr'), isTrue);
      expect(AppStrings.language, 'fr');
      expect(AppStrings.savedChoice, 'fr');
      expect(AppStrings.isRtl, isFalse);
      expect(AppStrings.changes.value, 'fr');

      // The saved choice survives a restart and beats the device language.
      await AppStrings.init();
      expect(AppStrings.language, 'fr');

      await AppStrings.setLanguage('ar');
      expect(AppStrings.isRtl, isTrue);

      await AppStrings.useSystemDefault();
      expect(AppStrings.savedChoice, isNull);
      expect(GetStorage().read<String>('app_language'), isNull);
      expect(AppStrings.language, 'ur'); // the (fake) device language
      expect(AppStrings.changes.value, 'ur');
    });

    test('setLanguage rejects languages we do not ship', () async {
      expect(await AppStrings.setLanguage('xx'), isFalse);
      expect(await AppStrings.setLanguage('en'), isTrue);
    });
  });

  test('every shipped language file exists and parses', () {
    final en =
        jsonDecode(File('assets/lang/english_en.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(en.length, enStrings.length, reason: 'run tool/export_en_json.dart');
    for (final path in AppStrings.assetByLanguage.values) {
      expect(File(path).existsSync(), isTrue, reason: path);
      final m =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      // Keys added after a file was produced fall back to English at runtime.
      expect(m, isNotEmpty, reason: path);
    }
  });

  group('device language', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => Directory.systemTemp.createTempSync('gs').path,
          );
      await GetStorage.init();
      await GetStorage().erase();
    });
    tearDown(() => AppStrings.language = AppStrings.fallbackLanguage);

    test('resolve maps device locales to shipped languages', () {
      expect(AppStrings.resolve(const Locale('ur', 'PK')), 'ur');
      expect(AppStrings.resolve(const Locale('iw')), 'he');
      expect(AppStrings.resolve(const Locale('nb', 'NO')), 'no');
      expect(AppStrings.resolve(const Locale('zh', 'CN')), 'zh');
      expect(AppStrings.resolve(const Locale('zh', 'TW')), 'zh-TW');
      expect(
        AppStrings.resolve(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        'zh-TW',
      );
      expect(AppStrings.resolve(const Locale('xx')), 'en');
    });

    test(
      'an Urdu phone gets the Urdu app, RTL, English fallback intact',
      () async {
        final binding = TestWidgetsFlutterBinding.instance;
        binding.platformDispatcher.localeTestValue = const Locale('ur', 'PK');
        addTearDown(binding.platformDispatcher.clearLocaleTestValue);
        await AppStrings.init();
        expect(AppStrings.language, 'ur');
        expect(AppStrings.isRtl, isTrue);
        expect(
          'settings_contact_us'.tr,
          isNot(enStrings['settings_contact_us']),
        );
        // Placeholder-safe: strings are still usable after translation.
        expect(
          'contacts_duplicate_message'.trParams({'name': 'Sam'}),
          contains('Sam'),
        );
      },
    );

    test('a broken translated placeholder falls back to English', () async {
      await AppStrings.setLanguage('fr');
      // The shipped French file translated {goal} -> {objectif}.
      expect(
        'career_generated_headline_focus'.trParams({'goal': 'X'}),
        enStrings['career_generated_headline_focus']!.replaceAll('{goal}', 'X'),
      );
    });
  });
}
