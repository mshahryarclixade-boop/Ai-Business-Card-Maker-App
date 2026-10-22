import 'dart:io';

import 'package:ai_business_card_maker/app/core/translations/app_strings.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/settings/view/language_view.dart';
import 'package:ai_business_card_maker/app/modules/settings/view/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// The Settings language card + sheet: picking a language updates the
/// running app (text and direction) and "System default" clears the choice.
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

  Future<void> settle(WidgetTester t) async {
    // Language files load through the real asset bundle, so alternate real
    // time with frame pumps until the async switch has finished.
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpApp(WidgetTester t) async {
    Get.reset();
    Get.put(ProfileStore());
    await GetStorage().erase();
    t.view.physicalSize = const Size(360 * 3, 740 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.runAsync(AppStrings.init);
    // Mirrors main.dart: the app pushes the new locale when the language
    // changes.
    void onChange() => Get.updateLocale(AppStrings.locale);
    AppStrings.changes.addListener(onChange);
    addTearDown(() => AppStrings.changes.removeListener(onChange));
    await t.pumpWidget(
      GetMaterialApp(
        locale: AppStrings.locale,
        supportedLocales: AppStrings.supportedLocales
            .where(GlobalMaterialLocalizations.delegate.isSupported)
            .toList(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SettingsView(),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
  }

  TextDirection dir(WidgetTester t) =>
      Directionality.of(t.element(find.byType(SettingsView, skipOffstage: false)));

  const names = [
    'English',
    'العربية',
    'हिन्दी',
    'Afrikaans',
    'Español',
    'Português',
    'Bahasa Indonesia',
    '中文',
    '한국어',
    '日本語',
    'Italiano',
    'Français',
    'Deutsch',
    'Русский',
  ];

  testWidgets('card shows the current language; the screen lists all', (
    t,
  ) async {
    await pumpApp(t);
    addTearDown(() => t.runAsync(AppStrings.useSystemDefault));
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget); // card value (device = en)

    await t.tap(find.text('Language'));
    await t.pumpAndSettle();
    // Exactly this list, in this order, each in its own script.
    expect(kLanguageOptions.map((o) => o.nativeName), names);
    expect(find.text('اردو'), findsNothing);
    final ys = <double>[];
    for (final name in names.take(8)) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    for (final name in ['العربية', 'हिन्दी', 'Afrikaans']) {
      ys.add(t.getTopLeft(find.text(name).last).dy);
    }
    expect(ys, [...ys]..sort(), reason: 'rows are in the requested order');
  });

  testWidgets('picking Arabic updates text and direction live', (t) async {
    await pumpApp(t);
    addTearDown(() => t.runAsync(AppStrings.useSystemDefault));
    expect(dir(t), TextDirection.ltr);

    await t.tap(find.text('Language'));
    await t.pumpAndSettle();
    await t.tap(find.text('العربية'));
    await settle(t);
    await t.pumpAndSettle();

    expect(AppStrings.language, 'ar');
    expect(AppStrings.savedChoice, 'ar');
    expect(dir(t), TextDirection.rtl);
    expect(find.text('Language'), findsNothing); // title is now Arabic

    // Back to English.
    await t.tap(find.text('English'));
    await settle(t);
    await t.pumpAndSettle();
    expect(dir(t), TextDirection.ltr);
    expect(find.text('Language'), findsWidgets);
  });
}
