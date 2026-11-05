import 'dart:io';

import 'package:ai_business_card_maker/app/modules/home/controller/home_controller.dart';
import 'package:ai_business_card_maker/app/modules/onboarding/view/onboarding_view_v2.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/controller/business_details_controller.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/view/business_details_view.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/view/personal_details_view.dart';
import 'package:ai_business_card_maker/app/modules/template/model/template_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    Get.put(ProfileStore());
  });

  group('onboarding is one screen', () {
    for (final size in const [Size(320, 568), Size(375, 667), Size(414, 896), Size(800, 1280)]) {
      testWidgets('no pages, no scrolling, no overflow at $size', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(const GetMaterialApp(home: OnboardingViewV2()));
        await t.pumpAndSettle();
        expect(find.byType(PageView), findsNothing);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(Scrollable), findsNothing);
        expect(find.text('Create my Profile'), findsOneWidget);
        expect(find.text('I’ll do it later'), findsOneWidget);
        expect(t.takeException(), isNull);
        // Swiping does nothing: still the same single screen.
        await t.fling(find.byType(OnboardingViewV2), const Offset(-300, 0), 1000);
        await t.pumpAndSettle();
        expect(find.text('Create my Profile'), findsOneWidget);
      });
    }
  });

  group('swipe between Profile and Business', () {
    Future<void> open(WidgetTester t) async {
      await t.pumpWidget(GetMaterialApp(
        home: const PersonalDetailsView(),
        getPages: [GetPage(name: '/business', page: () => const BusinessDetailsView())],
      ));
      await t.pumpAndSettle();
    }

    testWidgets('swiping left with empty fields stays and shows the errors', (t) async {
      await open(t);
      await t.fling(find.byType(PersonalDetailsView), const Offset(-400, 0), 1500);
      await t.pumpAndSettle();
      expect(find.byType(PersonalDetailsView), findsOneWidget);
      expect(find.byType(BusinessDetailsView), findsNothing);
      expect(find.text('Please enter your full name'), findsOneWidget);
    });

    testWidgets('swiping right on Business comes back to Profile', (t) async {
      await open(t);
      // What onContinue does once the required fields are valid (it also
      // logs analytics, which needs Firebase, so it is not called here).
      Get.toNamed('/business');
      await t.pumpAndSettle();
      expect(find.byType(BusinessDetailsView), findsOneWidget);
      await t.fling(find.byType(BusinessDetailsView), const Offset(400, 0), 1500);
      await t.pumpAndSettle();
      expect(find.byType(BusinessDetailsView), findsNothing);
      expect(find.byType(PersonalDetailsView), findsOneWidget);
    });

    testWidgets('what was typed on Business is still there after swiping back and forth', (t) async {
      await open(t);
      Get.toNamed('/business');
      await t.pumpAndSettle();
      final b = Get.find<BusinessDetailsController>();
      b.companyController.text = 'Acme Corporation';
      b.designationController.text = 'Product Developer';
      b.selectWebsite();
      b.websiteController.text = 'https://www.acme.com';
      await t.pump();
      await t.fling(find.byType(BusinessDetailsView), const Offset(400, 0), 1500);
      await t.pumpAndSettle();
      expect(find.byType(BusinessDetailsView), findsNothing);

      Get.toNamed('/business');
      await t.pumpAndSettle();
      final again = Get.find<BusinessDetailsController>();
      expect(again.companyController.text, 'Acme Corporation');
      expect(again.designationController.text, 'Product Developer');
      expect(again.websiteController.text, 'https://www.acme.com');
      // The website field is showing, not hidden behind "no choice yet".
      expect(find.text('https://www.acme.com'), findsWidgets);
    });

    testWidgets('a slow drag is not a swipe', (t) async {
      await open(t);
      await t.timedDrag(find.byType(PersonalDetailsView), const Offset(-200, 0), const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.text('Please enter your full name'), findsNothing);
    });
  });

  group('Free Templates order', () {
    const a = TemplateItem(id: 'a', name: 'A', category: 'c', orientation: TemplateOrientation.horizontal, frontImagePath: 'a', backImagePath: 'a');
    const b = TemplateItem(id: 'b', name: 'B', category: 'c', orientation: TemplateOrientation.horizontal, frontImagePath: 'b', backImagePath: 'b');
    const c = TemplateItem(id: 'c', name: 'C', category: 'c', orientation: TemplateOrientation.horizontal, frontImagePath: 'c', backImagePath: 'c');

    List<String> ids(List<TemplateItem> l) => [for (final t in l) t.id];

    test('the AI card is first by default, the rest keep their order', () {
      final h = HomeController();
      expect(ids(h.orderedTemplates([a, b, c])), [kAiCardTemplateId, 'a', 'b', 'c']);
    });

    test('an applied template moves to the first position, latest first', () {
      final h = HomeController();
      h.templateOrder.assignAll(['b']);
      expect(ids(h.orderedTemplates([a, b, c])), ['b', kAiCardTemplateId, 'a', 'c']);
      h.templateOrder.assignAll(['c', 'b']);
      expect(ids(h.orderedTemplates([a, b, c])), ['c', 'b', kAiCardTemplateId, 'a']);
      h.templateOrder.assignAll([kAiCardTemplateId, 'a']);
      expect(ids(h.orderedTemplates([a, b, c])), [kAiCardTemplateId, 'a', 'b', 'c']);
    });
  });
}
