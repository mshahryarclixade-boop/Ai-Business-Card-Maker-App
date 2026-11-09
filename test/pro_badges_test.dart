import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/home/controller/home_controller.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/home_templates_section.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/model/qr_profile_data.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/view/qr_style_picker_screen.dart';
import 'package:ai_business_card_maker/app/modules/template/controller/template_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fonts.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}
}

class _FakeHome extends HomeController {
  @override
  void onReady() {}
}

const _sizes = <String, Size>{
  'phone 393x852': Size(393, 852),
  'small phone 320x568': Size(320, 568),
  'tablet 820x1180': Size(820, 1180),
  'tablet landscape 1180x820': Size(1180, 820),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Sub sub;
  final badge = find.byKey(const Key('pro_crown_badge'));

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
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    await GetStorage().erase();
    sub = _Sub();
    Get.put<SubscriptionController>(sub);
    Get.put(ProfileStore());
  });

  void size(WidgetTester t, Size s) {
    t.view.physicalSize = s * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  // ------------------------------------------------------------------- QR
  group('QR style picker', () {
    Future<void> pumpPicker(WidgetTester t, Size s) async {
      size(t, s);
      await t.pumpWidget(
        const GetMaterialApp(
          home: QrStylePickerScreen(
            form: {'fullName': 'Sara Khan', 'company': 'Studio K'},
            profile: QrProfileData(
              fullName: 'Sara Khan',
              companyName: 'Studio K',
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 400));
    }

    testWidgets('a crown on every style except Classic (free user)', (t) async {
      await pumpPicker(t, _sizes['phone 393x852']!);
      expect(find.text('Classic'), findsOneWidget);
      // 7 styles: Classic + 6 Pro styles.
      expect(badge, findsNWidgets(6));
      // None inside the Classic tile.
      final classicTile = find.ancestor(
        of: find.text('Classic'),
        matching: find.byType(Stack),
      );
      expect(
        find.descendant(of: classicTile.first, matching: badge),
        findsNothing,
      );
      for (final name in [
        'Rounded',
        'Dots',
        'Midnight',
        'Ocean',
        'Forest',
        'Sunset',
      ]) {
        final tile = find
            .ancestor(of: find.text(name), matching: find.byType(Stack))
            .first;
        expect(
          find.descendant(of: tile, matching: badge),
          findsOneWidget,
          reason: name,
        );
      }
    });

    testWidgets('Pro users see no badges', (t) async {
      sub.isUserPro.value = true;
      await pumpPicker(t, _sizes['phone 393x852']!);
      expect(badge, findsNothing);
    });

    testWidgets('the badge is visual only: tapping the tile still selects it', (
      t,
    ) async {
      await pumpPicker(t, _sizes['phone 393x852']!);
      await t.tap(find.text('Midnight'));
      await t.pump();
      expect(t.takeException(), isNull);
    });

    for (final s in _sizes.entries) {
      testWidgets('no overflow on ${s.key}', (t) async {
        await pumpPicker(t, s.value);
        expect(t.takeException(), isNull);
        expect(badge, findsNWidgets(6));
      });
    }
  });

  // ------------------------------------------------------------ Home list
  group('Home templates', () {
    Future<TemplateController> pumpHome(WidgetTester t, Size s) async {
      size(t, s);
      Get.put<HomeController>(_FakeHome());
      final svc = Get.put(RecentDesignsService());
      svc.designs.add(
        RecentDesign(
          id: '1',
          path: 'x.png',
          savedAt: DateTime(2025),
          title: 'Card',
          designData: const {},
        ),
      );
      final templates = Get.put(TemplateController());
      await t.runAsync(() async {
        for (var i = 0; i < 100 && templates.isLoading.value; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await t.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HomeTemplatesSection()),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 400));
      return templates;
    }

    testWidgets('free templates first, Pro ones after, with a crown', (
      t,
    ) async {
      final templates = await pumpHome(t, _sizes['phone 393x852']!);
      final list = templates.allTemplates
          .where((x) => x.orientation.name == 'horizontal')
          .toList();
      final firstPro = list.indexWhere((x) => x.isPremium);
      expect(firstPro, greaterThan(0)); // some free first...
      expect(
        list.skip(firstPro).any((x) => x.isPremium),
        isTrue,
      ); // ...then Pro
      expect(list.take(firstPro).every((x) => !x.isPremium), isTrue);

      // A crown on the Pro tiles only (test images have no size, so more
      // tiles are built than a device shows): never more crowns than Pro
      // templates, and none on the AI card or the free ones.
      final premium = list.where((x) => x.isPremium).length;
      expect(badge, findsWidgets);
      expect(badge.evaluate().length, lessThanOrEqualTo(premium));
    });

    testWidgets('Pro users see no crowns, even on Pro templates', (t) async {
      sub.isUserPro.value = true;
      await pumpHome(t, _sizes['phone 393x852']!);
      await t.drag(find.byType(ListView).first, const Offset(-3000, 0));
      await t.pump(const Duration(milliseconds: 400));
      expect(badge, findsNothing);
    });

    testWidgets('tapping a Pro template still previews it (badge is visual)', (
      t,
    ) async {
      await pumpHome(t, _sizes['phone 393x852']!);
      await t.drag(find.byType(ListView).first, const Offset(-3000, 0));
      await t.pump(const Duration(milliseconds: 400));
      final controller = Get.find<HomeController>();
      expect(controller.previewTemplate.value, isNull);
      await t.tap(badge.first, warnIfMissed: false); // badge ignores pointers
      await t.pump();
      expect(t.takeException(), isNull);
    });

    for (final s in _sizes.entries) {
      testWidgets('no overflow on ${s.key}', (t) async {
        await pumpHome(t, s.value);
        await t.drag(find.byType(ListView).first, const Offset(-3000, 0));
        await t.pump(const Duration(milliseconds: 400));
        expect(t.takeException(), isNull);
      });
    }
  });
}
