import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_business_card_maker/app/core/translations/app_strings.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_hub_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/career_studio_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_builder_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_optimizer_view.dart';
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

const _free = CareerHubState();
const _pro = CareerHubState.pro();
const _returning = CareerHubState(
  hasDraft: true,
  score: 54,
  fixesDone: 2,
  scansLeft: 0,
  buildsLeft: 0,
);
const _buildUsed = CareerHubState(buildsLeft: 0, hasDraft: true);
const _scanUsed = CareerHubState(scansLeft: 0, score: 54);

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

  setUp(() {
    Get.reset();
    Get.put(ProfileStore());
  });

  final key = GlobalKey();
  Future<void> pump(WidgetTester t, CareerHubState s) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: CareerStudioView(initial: s),
        ),
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

  testWidgets('CS01 Free: hero, tools, badges, no LinkedIn wording', (t) async {
    await pump(t, _free);
    expect(find.text('Career Studio'), findsOneWidget);
    expect(find.text('Get found by the right people'), findsOneWidget);
    expect(find.text('Free this month'), findsOneWidget);
    expect(find.text('1 build · 1 scan left'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('1 FREE'), findsNWidgets(2));
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.textContaining('LinkedIn'), findsNothing);
    expect(find.text('PRO'), findsNothing); // crown button, not the badge
    await shot(t, 'cs01_free');
  });

  testWidgets('CS02 Pro: PRO badge, unlimited', (t) async {
    await pump(t, _pro);
    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('Pro plan'), findsOneWidget);
    expect(find.text('Unlimited'), findsOneWidget);
    expect(find.text('UNLIMITED'), findsNWidgets(2));
    await shot(t, 'cs02_pro');
  });

  testWidgets('CS03 returning user: score + draft cards', (t) async {
    await pump(t, _returning);
    expect(find.text('LinkedIn score: 54'), findsOneWidget);
    expect(find.text('2 of 7 fixes done · tap to continue'), findsOneWidget);
    expect(find.text('Your new profile draft'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('USED'), findsNWidgets(2));
    await shot(t, 'cs03_returning');
  });

  testWidgets('CS04 Post Planner popup', (t) async {
    await pump(t, _free);
    await t.tap(find.text('Post Planner'));
    await t.pumpAndSettle();
    expect(find.text('AI post writer in your voice'), findsOneWidget);
    expect(find.text('Notify me when it\'s ready'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    await shot(t, 'cs04_post_planner');
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('CS05 upgrade popup from the crown', (t) async {
    await pump(t, _free);
    await t.tap(
      find.byIcon(Icons.circle).hitTestable().evaluate().isEmpty
          ? find.byType(GestureDetector).at(1)
          : find.byIcon(Icons.circle),
    );
    await t.pumpAndSettle();
    expect(find.text('Unlock everything in Career Studio'), findsOneWidget);
    expect(find.text('GO PRO'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    await shot(t, 'cs05_upgrade');
  });

  testWidgets('CS06 free build used popup; tools open otherwise', (t) async {
    await pump(t, _buildUsed);
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    expect(find.text("You've used this month's free build"), findsOneWidget);
    expect(find.text('Get unlimited builds with Pro'), findsOneWidget);
    expect(find.text('Open my current draft'), findsOneWidget);
    expect(find.textContaining('Remind me on'), findsOneWidget);
    expect(find.byType(ProfileBuilderView), findsNothing);
    await shot(t, 'cs06_build_used');
  });

  testWidgets('CS07 free scan used popup', (t) async {
    await pump(t, _scanUsed);
    await t.tap(find.text('Profile Optimizer'));
    await t.pumpAndSettle();
    expect(find.text("You've used this month's free scan"), findsOneWidget);
    expect(find.text('Get unlimited scans with Pro'), findsOneWidget);
    expect(find.text('Open my last report'), findsOneWidget);
    expect(find.byType(ProfileOptimizerView), findsNothing);
    await shot(t, 'cs07_scan_used');
    await t.tap(find.text('Open my last report'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileReportView), findsOneWidget);
  });

  testWidgets('free allowance left: tools open their screens', (t) async {
    await pump(t, _free);
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileBuilderView), findsOneWidget);
  });

  testWidgets('RTL (Arabic): hub lays out right to left without overflow', (
    t,
  ) async {
    await t.runAsync(() => AppStrings.setLanguage('ar'));
    addTearDown(() => AppStrings.language = 'en');
    await pump(t, _returning);
    expect(tester(t), isNull);
  });
}

Object? tester(WidgetTester t) => t.takeException();
