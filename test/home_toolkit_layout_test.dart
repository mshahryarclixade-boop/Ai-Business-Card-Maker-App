import 'dart:io';

import 'package:ai_business_card_maker/app/modules/home/widgets/ai_toolkit_section.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/core/translations/en_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_fonts.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('tk').path,
        );
    await GetStorage.init();
    await loadRobotoAsSfPro();
  });

  setUp(() {
    Get.reset();
    Get.put<SubscriptionController>(_Sub());
  });

  test('the Home section is titled "Templates"', () {
    expect(enStrings['home_templates_free_heading'], 'Templates');
  });

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(body: Padding(padding: EdgeInsets.all(20), child: AiToolkitSection())),
      ),
    );
    await t.pump();
  }

  testWidgets('both cards: same gap after the icon, PRO at the far right',
      (t) async {
    await pump(t);
    expect(t.takeException(), isNull);
    final career = t.getRect(find.text('Career Studio'));
    final expert = t.getRect(find.text('Business Panel').evaluate().isNotEmpty
        ? find.text('Business Panel')
        : find.text(enStrings['home_toolkit_expert_title']!));
    // Texts start at the same distance from their card's left edge (cards have
    // 12 / 14 px padding): the icon column + gap are identical.
    expect((expert.left - career.left).abs(), lessThanOrEqualTo(2.5));

    // PRO is the right-most thing in its card.
    final pro = t.getRect(find.text('PRO'));
    final card = t.getRect(find.byType(AiToolkitSection));
    expect(card.right - pro.right, lessThan(14 + 10 + 4));
    expect(pro.left, greaterThan(expert.left + 100)); // not next to the title
  });
}
