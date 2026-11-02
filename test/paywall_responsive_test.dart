import 'dart:io';

import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
import 'package:ai_business_card_maker/app/modules/paywall/widgets/paywall_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSub extends SubscriptionController {
  @override
  void onInit() {}
}

/// The app's font (SFPro) isn't bundled in tests: Roboto stands in, so text
/// is measured like a real font instead of the wide test font.
Future<void> _loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk == null) return;
  final loader = FontLoader('SFPro');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    final file = File('$sdk/bin/cache/artifacts/material_fonts/$f');
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);
  group('scale', () {
    test('design size is 1:1', () {
      expect(PaywallCanvas.scaleFor(393, 860), 1.0);
    });
    test('fits both width and height', () {
      expect(PaywallCanvas.scaleFor(430, 800), closeTo(800 / 860, 1e-9)); // tall enough? height-bound
      expect(PaywallCanvas.scaleFor(393, 1200), 1.0); // taller: width-bound
    });
    test('small phones never get unreadably small', () {
      // 375 x 623 would fit at 0.72: held at 0.82 and scrolled.
      expect(PaywallCanvas.scaleFor(375, 623), PaywallCanvas.minReadableScale);
      // Very narrow: width decides.
      expect(PaywallCanvas.scaleFor(320, 480), closeTo(320 / 393, 1e-9));
    });
    test('tablets are capped and centred', () {
      expect(PaywallCanvas.scaleFor(820, 1100), closeTo(1100 / 860, 1e-9));
      expect(PaywallCanvas.scaleFor(1366, 1000), closeTo(1000 / 860, 1e-9));
      expect(PaywallCanvas.scaleFor(3000, 4000), PaywallCanvas.maxScale);
    });
  });

  const sizes = {
    'small phone 320x568': Size(320, 568),
    'iPhone SE 375x667': Size(375, 667),
    'phone 393x852': Size(393, 852),
    'large phone 430x932': Size(430, 932),
    'phone landscape 852x393': Size(852, 393),
    'small tablet 600x960': Size(600, 960),
    'iPad 820x1180': Size(820, 1180),
    'iPad Pro 1024x1366': Size(1024, 1366),
    'iPad landscape 1180x820': Size(1180, 820),
  };

  for (final screen in {'paywall 1': () => const PaywallView(), 'paywall 2': () => const PaywallView2()}.entries) {
    for (final s in sizes.entries) {
      testWidgets('${screen.key} on ${s.key}: no overflow, canvas inside the screen', (t) async {
        SharedPreferences.setMockInitialValues({});
        Get.reset();
        Get.put<SubscriptionController>(_FakeSub());
        t.view.physicalSize = s.value * 2;
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        await t.pumpWidget(GetMaterialApp(home: screen.value()));
        await t.pump(const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);

        final box = t.getRect(find.descendant(of: find.byType(PaywallCanvas), matching: find.byType(FittedBox)).first);
        // Never wider than the screen, and centred horizontally.
        expect(box.width, lessThanOrEqualTo(s.value.width + 0.5));
        expect(box.center.dx, closeTo(s.value.width / 2, 1));
        // Fits the height unless it is a small screen (then it scrolls).
        final scale = PaywallCanvas.scaleFor(s.value.width, s.value.height - 0); // safe area is 0 in tests
        if (scale > PaywallCanvas.minReadableScale + 1e-9) {
          expect(box.height, lessThanOrEqualTo(s.value.height + 0.5));
        } else {
          expect(find.byType(SingleChildScrollView), findsOneWidget);
        }
        await t.pumpWidget(const SizedBox());
      });
    }
  }
}
