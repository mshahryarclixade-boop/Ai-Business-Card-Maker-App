import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_business_card_maker/app/core/translations/app_strings.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_score_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/service/career_ai_service.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_analyzing_view.dart';
import 'fake_career_ai.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_fix_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_report_view.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

const _shots = String.fromEnvironment('SHOTS_DIR');

Future<void> _loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk == null) return;
  final root = '$sdk/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('SFPro');
  for (final f in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    final file = File('$root/$f');
    if (file.existsSync()) {
      loader.addFont(
        Future.value(ByteData.view(file.readAsBytesSync().buffer)),
      );
    }
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final key = GlobalKey();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
    await _loadFonts();
  });

  setUp(() {
    Get.reset();
    Get.put(ProfileStore());
    CareerScoreStore.clear();
    CareerAi.instance = FakeCareerAi();
  });

  Future<void> pump(WidgetTester t, Widget home) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: key, child: home),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> shot(WidgetTester t, String name) async {
    if (_shots.isEmpty) return;
    await t.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('CS25 analyzing, then the report opens', (t) async {
    await pump(t, const ProfileAnalyzingView(duration: Duration(seconds: 1)));
    expect(find.text('Checking 7 parts of your profile'), findsOneWidget);
    for (final p in [
      'Headline',
      'About',
      'Experience',
      'Skills',
      'Featured',
      'Banner',
      'Profile link',
    ]) {
      expect(find.text(p), findsOneWidget, reason: p);
    }
    expect(find.text('Takes about 15 seconds'), findsOneWidget);
    await shot(t, 'cs25_analyzing');
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    expect(find.byType(ProfileReportView), findsOneWidget);
  });

  testWidgets('CS26 free report: no score breakdown by default', (t) async {
    await pump(t, const ProfileReportView(isPro: false));
    expect(find.text('Profile report'), findsOneWidget);
    expect(find.text('54'), findsOneWidget);
    expect(find.text('of 100'), findsOneWidget);
    expect(find.text('NEEDS WORK'), findsOneWidget);
    expect(find.text('Fixing everything could take you to 90'), findsOneWidget);
    expect(find.text('Fixes · 0 of 7 done'), findsOneWidget);
    expect(find.text('By impact'), findsOneWidget);
    expect(find.text('HIGH impact · +8 points'), findsOneWidget);
    expect(find.text('Fix'), findsNWidgets(2));
    expect(find.text('PRO'), findsNWidgets(5));
    expect(find.text('Fix the 2 free issues'), findsOneWidget);
    expect(find.text('Fix all 7 with Pro'), findsOneWidget);
    expect(find.textContaining('LinkedIn'), findsNothing);
    // The breakdown is hidden until the icon is tapped.
    expect(find.text('Score breakdown'), findsNothing);
    expect(find.text('Photo & banner'), findsNothing);
    await shot(t, 'cs26_report_free');
  });

  testWidgets('CS27 score breakdown opens from the top-right icon only', (
    t,
  ) async {
    await pump(t, const ProfileReportView(isPro: false));
    await t.tap(find.byIcon(Icons.bar_chart_rounded));
    await t.pumpAndSettle();
    expect(find.text('Score breakdown'), findsOneWidget);
    expect(
      find.text('Each part is scored on what recruiters and clients look for.'),
      findsOneWidget,
    );
    for (final s in [
      'Headline',
      'About',
      'Experience',
      'Skills',
      'Photo & banner',
      'Featured',
      'Profile link',
    ]) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    for (final v in ['30', '40', '78', '62', '60', '0', '50']) {
      expect(find.text(v), findsOneWidget, reason: v);
    }
    await shot(t, 'cs27_breakdown');
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    expect(find.text('Score breakdown'), findsNothing);
  });

  testWidgets('CS28/29 fix flow: suggestion, try another, use this', (t) async {
    await pump(t, const ProfileReportView(isPro: false));
    await t.tap(find.text('Headline is only a job title'));
    await t.pumpAndSettle();
    expect(find.text('Fix this issue'), findsOneWidget);
    expect(find.text('HIGH IMPACT'), findsOneWidget);
    expect(find.text('+8 POINTS'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Designer'), findsOneWidget);
    expect(find.text('Suggested'), findsOneWidget);
    expect(find.text('3 AI rewrites left this month'), findsOneWidget);
    // The suggestion is written by the AI.
    expect(find.text('AI suggestion 1 for headline'), findsOneWidget);
    await shot(t, 'cs28_fix_headline');

    await t.tap(find.text('Try another'));
    await t.pump();
    expect(find.text('2 AI rewrites left this month'), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.text('AI suggestion 1 for headline'), findsNothing);
    expect(find.text('AI suggestion 2 for headline'), findsOneWidget);

    await t.tap(find.text('Use this'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileFixView), findsNothing);
    expect(find.text('Fixes · 1 of 7 done'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('With your fixes: about 62'), findsOneWidget);

    // Second free fix.
    await t.tap(find.text('About is under 3 lines'));
    await t.pumpAndSettle();
    expect(find.text('+6 POINTS'), findsOneWidget);
    await shot(t, 'cs29_fix_about');
    await t.tap(find.text('Use this'));
    await t.pumpAndSettle();
    expect(find.text('Fixes · 2 of 7 done'), findsOneWidget);
    expect(find.text('With your fixes: about 68'), findsOneWidget);
    // Only the upsell is left.
    expect(find.text('Fix the 2 free issues'), findsNothing);
    expect(find.text('Unlock 5 more fixes'), findsOneWidget);
    await shot(t, 'cs30_report_done');
  });

  testWidgets('edit the suggestion by hand', (t) async {
    await pump(t, const ProfileReportView(isPro: false));
    await t.tap(find.text('About is under 3 lines'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'My own about text');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('My own about text'), findsOneWidget);
  });

  testWidgets('free rewrites run out: popup instead of a new suggestion', (
    t,
  ) async {
    await pump(t, const ProfileReportView(isPro: false, rewritesLeft: 0));
    await t.tap(find.text('Headline is only a job title'));
    await t.pumpAndSettle();
    expect(find.text('0 AI rewrites left this month'), findsOneWidget);
    await t.tap(find.text('Try another'));
    await t.pumpAndSettle();
    expect(find.text('No AI rewrites left this month'), findsOneWidget);
  });

  testWidgets('Pro: every fix is open, no PRO badges, unlimited rewrites', (
    t,
  ) async {
    await pump(t, const ProfileReportView(isPro: true));
    expect(find.text('Fix'), findsNWidgets(7));
    expect(find.text('PRO'), findsNothing);
    expect(find.text('Fix all 7 issues'), findsOneWidget);
    expect(find.text('Fix all 7 with Pro'), findsNothing);
    await t.tap(find.text('No Featured section'));
    await t.pumpAndSettle();
    expect(find.text('Fix this issue'), findsOneWidget);
    expect(find.text('Pro · unlimited AI rewrites'), findsOneWidget);
    await shot(t, 'cs_pro_fix');
  });

  for (final lang in ['fr', 'de', 'ru', 'ar']) {
    testWidgets('report flow lays out without overflow in $lang', (t) async {
      await t.runAsync(() => AppStrings.setLanguage(lang));
      addTearDown(() => AppStrings.language = 'en');
      final overflows = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        final m = d.exceptionAsString();
        if (m.contains('overflowed')) {
          final loc = RegExp(r'lib/app/[^ \n:]*:\d+')
              .allMatches(d.toString())
              .map((x) => x[0])
              .toSet()
              .take(2)
              .join(', ');
          overflows.add('${m.split('\n').first} @ $loc');
        } else {
          old?.call(d);
        }
      };
      await pump(t, const ProfileAnalyzingView(duration: Duration(minutes: 5)));
      await pump(t, const ProfileReportView(isPro: false));
      await t.tap(find.byIcon(Icons.bar_chart_rounded));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(5, 5)); // dismiss the sheet
      await t.pumpAndSettle();
      await t.tap(find.byType(GestureDetector).at(3)); // first fix row
      await t.pumpAndSettle();
      await t.tap(find.byType(OutlinedButton)); // Try another
      await t.pump();
      FlutterError.onError = old;
      expect(overflows, isEmpty, reason: lang);
    });
  }
}
