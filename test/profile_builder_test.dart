import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_business_card_maker/app/core/translations/app_strings.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/profile_builder_flow_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_builder_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_building_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_draft_view.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/model/user_profile_data.dart';
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
    ProfileStore.to.profile.value = const UserProfileData(
      fullName: 'Ayesha Raza',
      designation: 'Product Designer',
      companyName: 'Northwind Studio',
    );
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

  testWidgets('CS08 step 1: details prefilled from the card', (t) async {
    await pump(t, const ProfileBuilderView(isPro: false));
    expect(find.text('Profile Builder'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Check your details'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    for (final v in ['Ayesha Raza', 'Product Designer', 'Northwind Studio']) {
      expect(find.text(v), findsOneWidget, reason: v);
    }
    for (final b in ['0–2 yrs', '3–5 yrs', '6–10 yrs', '10+ yrs']) {
      expect(find.text(b), findsOneWidget, reason: b);
    }
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('LinkedIn'), findsNothing);
    await shot(t, 'cs08_step1');
  });

  testWidgets('steps 2 and 3, back arrow, audience cap, free note', (t) async {
    await pump(t, const ProfileBuilderView(isPro: false));
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.text('Who should find you?'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    await shot(t, 'cs10_step2');

    // Startup founders + Product managers are preselected; a 3rd is allowed,
    // a 4th is ignored.
    final c = Get.find<ProfileBuilderFlowController>();
    await t.tap(find.text('Recruiters'));
    await t.tap(find.text('Investors'));
    await t.pump();
    expect(c.audience.length, 3);
    expect(c.audience.contains('Investors'), isFalse);
    await t.tap(find.text('Get hired'));
    await t.pump();
    expect(c.goal.value, 'Get hired');

    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.text('How should you sound?'), findsOneWidget);
    expect(find.text('Uses your 1 free build this month'), findsOneWidget);
    expect(find.text('Generate my profile'), findsOneWidget);
    await t.tap(find.text('Friendly'));
    await t.pump();
    expect(c.tone.value, 'Friendly');
    await shot(t, 'cs11_step3');

    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await t.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
  });

  testWidgets('Pro: no free-build note on the last step', (t) async {
    await pump(t, const ProfileBuilderView(isPro: true));
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text('Generate my profile'), findsOneWidget);
    expect(find.text('Uses your 1 free build this month'), findsNothing);
  });

  testWidgets('CS09 leave dialog: close asks first; answers are kept', (
    t,
  ) async {
    await pump(
      t,
      Builder(
        builder: (c) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(c).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileBuilderView(isPro: false),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextField, 'Northwind Studio'),
      'Acme',
    );
    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pumpAndSettle();
    expect(find.text('Leave the builder?'), findsOneWidget);
    expect(
      find.text(
        'Your answers are saved. Pick up where you left off from Career Studio.',
      ),
      findsOneWidget,
    );
    await t.tap(find.text('Keep going'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileBuilderView), findsOneWidget);

    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pumpAndSettle();
    await t.tap(find.text('Leave'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileBuilderView), findsNothing);

    // Coming back: the edited answer is still there.
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Acme'), findsOneWidget);
  });

  testWidgets('CS12 loading, then the draft opens', (t) async {
    await pump(t, const ProfileBuildingView(isPro: false));
    expect(find.text('Writing your profile'), findsOneWidget);
    expect(find.text('Reading your details'), findsOneWidget);
    expect(find.text('Takes about 20 seconds'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await shot(t, 'cs12_loading');
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.byType(ProfileDraftView), findsOneWidget);
  });

  testWidgets('CS13 draft (Free): sections, Copy, no LinkedIn button', (
    t,
  ) async {
    await pump(t, const ProfileDraftView(isPro: false));
    expect(find.text('Your new profile'), findsOneWidget);
    expect(find.text('3 REWRITES LEFT'), findsOneWidget);
    for (final s in ['Headline', 'About', 'Experience']) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
    expect(find.text('Copy'), findsNWidgets(3));
    expect(find.text('Edit'), findsNWidgets(3));
    expect(find.text('Rewrite'), findsNWidgets(3));
    expect(find.textContaining('LinkedIn'), findsNothing);
    await shot(t, 'cs13_draft_free');

    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    await t.tap(find.text('Copy').first);
    await t.pump();
    expect(copied, startsWith('Product Designer at Northwind Studio'));
    expect(find.text('Copied'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('CS14 draft (Pro): unlimited rewrites never run out', (t) async {
    await pump(t, const ProfileDraftView(isPro: true));
    expect(find.text('UNLIMITED REWRITES'), findsOneWidget);
    final before =
        (t.widget(find.textContaining('Product Designer at').first) as Text)
            .data;
    for (var i = 0; i < 5; i++) {
      await t.tap(find.text('Rewrite').first);
      await t.pump();
    }
    expect(find.text('UNLIMITED REWRITES'), findsOneWidget);
    expect(find.text('No AI rewrites left this month'), findsNothing);
    expect(before, isNotEmpty);
    await shot(t, 'cs14_draft_pro');
  });

  testWidgets('CS15 edit by hand: char count, Cancel keeps, Save updates', (
    t,
  ) async {
    await pump(t, const ProfileDraftView(isPro: false));
    await t.tap(find.text('Edit').first);
    await t.pumpAndSettle();
    expect(find.text('Edit headline'), findsOneWidget);
    expect(find.textContaining('characters'), findsOneWidget);
    await shot(t, 'cs15_edit');

    await t.enterText(find.byType(TextField), 'New headline');
    await t.pump();
    expect(find.text('12 characters'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('New headline'), findsNothing);

    await t.tap(find.text('Edit').first);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'New headline');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('New headline'), findsOneWidget);
  });

  testWidgets('CS16 free rewrites run out: popup, then Edit it myself', (
    t,
  ) async {
    await pump(t, const ProfileDraftView(isPro: false));
    for (var i = 3; i > 0; i--) {
      expect(find.text('$i REWRITES LEFT'), findsOneWidget);
      await t.tap(find.text('Rewrite').first);
      await t.pump();
    }
    expect(find.text('0 REWRITES LEFT'), findsOneWidget);

    await t.tap(find.text('Rewrite').first);
    await t.pumpAndSettle();
    expect(find.text('No AI rewrites left this month'), findsOneWidget);
    expect(find.text('Get unlimited rewrites with Pro'), findsOneWidget);
    await shot(t, 'cs16_no_rewrites');

    await t.tap(find.text('Edit it myself'));
    await t.pumpAndSettle();
    expect(find.text('Edit headline'), findsOneWidget);
  });

  // Long-text languages and RTL: walk the whole flow and fail on overflow.
  for (final lang in ['fr', 'de', 'ru', 'ar']) {
    testWidgets('whole flow lays out without overflow in $lang', (t) async {
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

      await pump(t, const ProfileBuilderView(isPro: false));
      await t.tap(find.byType(ElevatedButton)); // step 1 -> 2
      await t.pumpAndSettle();
      await t.tap(find.byType(ElevatedButton)); // step 2 -> 3
      await t.pumpAndSettle();
      await t.pumpWidget(
        GetMaterialApp(home: const ProfileBuildingView(isPro: false)),
      );
      await t.pump(const Duration(milliseconds: 200));
      await t.pumpWidget(
        GetMaterialApp(home: const ProfileDraftView(isPro: false)),
      );
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byType(GestureDetector).at(1)); // a Copy chip
      await t.pump(const Duration(seconds: 3));
      await t.tap(find.byIcon(Icons.auto_awesome).first);
      await t.pump();
      for (var i = 0; i < 3; i++) {
        await t.tap(find.byIcon(Icons.auto_awesome).first);
        await t.pump();
      }
      await t.pumpAndSettle(); // no-rewrites sheet is open
      FlutterError.onError = old;
      expect(overflows, isEmpty, reason: lang);
    });
  }
}
