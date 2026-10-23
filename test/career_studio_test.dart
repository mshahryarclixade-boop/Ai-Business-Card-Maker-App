import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_business_card_maker/app/core/theme/app_colors.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/career_studio_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/post_planner_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_builder_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_optimizer_view.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/ai_toolkit_section.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Where screenshots of the screens are written (set by the runner).
const _shots = String.fromEnvironment('SHOTS_DIR');

Future<void> _loadFonts() async {
  // The app's font family isn't bundled; Roboto stands in so text renders.
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

Widget _app(Widget home) =>
    GetMaterialApp(debugShowCheckedModeBanner: false, home: home);

Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  if (_shots.isEmpty) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _shotWrap(GlobalKey key, Widget child) =>
    RepaintBoundary(key: key, child: child);

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
    ProfileStore.to.profile.value = ProfileStore.to.profile.value;
  });

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  testWidgets('toolkit card opens Career Studio', (t) async {
    phone(t);
    await t.pumpWidget(_app(const Scaffold(body: AiToolkitSection())));
    expect(find.text('Your Business ToolKit'), findsOneWidget);
    expect(find.text('Career Studio'), findsOneWidget);
    expect(find.text('AI Business Analyst'), findsOneWidget);
    await t.tap(find.text('Career Studio'));
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
    expect(find.text('Post Planner'), findsOneWidget);
  });

  testWidgets('Career Studio card opens Career Studio', (t) async {
    phone(t);
    await t.pumpWidget(_app(const Scaffold(body: AiToolkitSection())));
    await t.tap(find.text('Career Studio'));
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
  });

  testWidgets('Home -> Career Studio -> Builder and Optimizer still open', (
    t,
  ) async {
    // Regression: both hops use Get.to(() => page); GetX named them alike
    // and dropped the second one as a duplicate route.
    phone(t);
    await t.pumpWidget(_app(const Scaffold(body: AiToolkitSection())));
    await t.tap(find.text('Career Studio'));
    await t.pumpAndSettle();
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileBuilderView), findsOneWidget);
    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pumpAndSettle();
    await t.tap(find.text('Leave'));
    await t.pumpAndSettle();
    await t.tap(find.text('Profile Optimizer'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileOptimizerView), findsOneWidget);
  });

  testWidgets('Career Studio cards open their screens', (
    t,
  ) async {
    phone(t);
    await t.pumpWidget(_app(const CareerStudioView()));
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileBuilderView), findsOneWidget);
    // The builder asks before closing; leave it.
    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pumpAndSettle();
    await t.tap(find.text('Leave'));
    await t.pumpAndSettle();
    await t.tap(find.text('Profile Optimizer'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileOptimizerView), findsOneWidget);
    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await t.pumpAndSettle();
    await t.tap(find.text('Post Planner'));
    await t.pumpAndSettle();
    // Post Planner isn't built yet: the card opens the "coming soon" popup.
    expect(find.byType(PostPlannerView), findsNothing);
    expect(find.text('Notify me when it\'s ready'), findsOneWidget);
  });

  testWidgets('Profile Optimizer: choosing a source selects it', (t) async {
    phone(t);
    await t.pumpWidget(_app(const ProfileOptimizerView()));
    await t.tap(find.text('Paste sections manually'));
    await t.pumpAndSettle();
    expect(
      find.text('Paste your headline, about and experience here'),
      findsOneWidget,
    );
  });

  testWidgets('screenshots', (t) async {
    phone(t);
    final k = GlobalKey();
    for (final e in <String, Widget>{
      'home_toolkit': Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(child: const AiToolkitSection()),
        ),
      ),
      'career_studio': const CareerStudioView(),
      'profile_builder': const ProfileBuilderView(),
      'profile_optimizer': const ProfileOptimizerView(),
    }.entries) {
      await t.pumpWidget(_app(_shotWrap(k, e.value)));
      await t.pumpAndSettle();
      await _shot(t, k, e.key);
    }
  });
}
