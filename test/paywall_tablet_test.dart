import 'dart:io';
import 'dart:math' as math;

import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'test_fonts.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}
}

const _tabletPortrait = Size(820, 1180);
const _tabletLandscape = Size(1180, 820);
const _phone = Size(393, 852);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Sub sub;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
    await loadRobotoAsSfPro();
  });

  setUp(() {
    Get.reset();
    sub = _Sub();
    Get.put<SubscriptionController>(sub);
  });

  Future<void> pump(WidgetTester t, Size s) async {
    t.view.physicalSize = s * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(const GetMaterialApp(home: PaywallView2()));
    await t.pump(const Duration(milliseconds: 300));
  }

  Rect card(WidgetTester t, String title) => t.getRect(
    find
        .ancestor(of: find.text(title), matching: find.byType(GestureDetector))
        .first,
  );

  for (final entry in {
    'tablet portrait': _tabletPortrait,
    'tablet landscape': _tabletLandscape,
  }.entries) {
    group('Paywall View 2 on ${entry.key}', () {
      final size = entry.value;

      testWidgets('content ~88% wide with a max width; CTA matches the cards', (
        t,
      ) async {
        await pump(t, size);
        expect(t.takeException(), isNull);
        final cta = t.getRect(
          find
              .ancestor(
                of: find.text('Continue'),
                matching: find.byType(InkWell),
              )
              .first,
        );
        final expected = math.min(size.width * 0.88, 640.0);
        expect(cta.width, closeTo(expected, 1.5));
        final monthly = card(t, 'Monthly');
        final yearly = card(t, 'Yearly');
        expect(monthly.left, closeTo(cta.left, 1.5));
        expect(yearly.right, closeTo(cta.right, 1.5));
        // Centred.
        expect((cta.left + cta.right) / 2, closeTo(size.width / 2, 1.5));
      });

      testWidgets('plan cards have the same height', (t) async {
        await pump(t, size);
        expect(
          card(t, 'Monthly').height,
          closeTo(card(t, 'Yearly').height, 0.5),
        );
        expect(card(t, 'Monthly').top, closeTo(card(t, 'Yearly').top, 0.5));
      });

      testWidgets('"Most Popular" is a small pill above a full "Yearly"', (
        t,
      ) async {
        await pump(t, size);
        final yearly = t.getRect(find.text('Yearly'));
        final pill = t.getRect(find.text('Most Popular'));
        expect(pill.bottom, lessThanOrEqualTo(yearly.top + 1)); // above
        expect((pill.left - yearly.left).abs(), lessThan(14)); // left aligned
        expect(pill.height, lessThan(20)); // small
        // Neither text is cut ("Y..." / "Most Pop...").
        for (final text in ['Yearly', 'Most Popular', 'Monthly']) {
          expect(
            t.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines,
            isFalse,
            reason: text,
          );
        }
        // The check mark is at the far right of the card.
        final yearlyCard = card(t, 'Yearly');
        final dot = t.getRect(
          find
              .descendant(
                of: find
                    .ancestor(
                      of: find.text('Yearly'),
                      matching: find.byType(GestureDetector),
                    )
                    .first,
                matching: find.byType(Icon),
              )
              .first,
        );
        expect(yearlyCard.right - dot.right, lessThan(30));
        // Both cards' titles and prices line up.
        expect(t.getRect(find.text('Monthly')).top, closeTo(yearly.top, 1));
        expect(
          t.getRect(find.text(r'$6.99')).top,
          closeTo(t.getRect(find.text(r'$29.99')).top, 3),
        );
      });

      testWidgets('price lines do not wrap; struck price and saving line up', (
        t,
      ) async {
        await pump(t, size);
        final note = t.getRect(find.text(r'$2.50/month, billed yearly'));
        expect(note.height, lessThan(24)); // one line
        final struck = t.getRect(find.text(r'$83.88/year'));
        final save = t.getRect(find.text('Save 64%'));
        expect((struck.center.dy - save.center.dy).abs(), lessThan(8));
        expect(
          save.left - struck.right,
          greaterThanOrEqualTo(8),
        ); // room between
      });

      testWidgets('chips form a 2 x 2 grid', (t) async {
        await pump(t, size);
        final r = [
          for (final s in [
            'Unlimited AI cards',
            'Unlimited scans',
            'No watermark',
            'All templates and QR styles',
          ])
            t.getRect(find.text(s)),
        ];
        expect((r[0].top - r[1].top).abs(), lessThan(3));
        expect((r[2].top - r[3].top).abs(), lessThan(3));
        expect(r[2].top, greaterThan(r[0].bottom));
        expect(r[1].left, greaterThan(r[0].right)); // two columns
        expect((r[0].left - r[2].left).abs(), lessThan(3)); // aligned columns
      });

      testWidgets('keeps the artwork: sparkles and the four icon badges', (
        t,
      ) async {
        await pump(t, size);
        for (final icon in [
          Icons.memory_rounded,
          Icons.gesture_rounded,
          Icons.grid_view_rounded,
          Icons.qr_code_2_rounded,
        ]) {
          expect(find.byIcon(icon), findsOneWidget, reason: '$icon');
        }
        expect(find.byIcon(Icons.auto_awesome), findsNWidgets(5));
      });

      testWidgets('close button is visible; footer and fine print are there', (
        t,
      ) async {
        await pump(t, size);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
        expect(find.text('Terms of Use'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('Restore Purchase'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('No commitment, cancel anytime'), findsOneWidget);
      });

      testWidgets('trial-eligible fine print uses the store price', (t) async {
        sub.yearlyTrialEligible.value = true;
        sub.yearlyTrialDays.value = 3;
        await pump(t, size);
        expect(
          find.text(r'3 days free, then $29.99/year. Cancel anytime.'),
          findsOneWidget,
        );
        expect(find.text('Continue'), findsOneWidget); // CTA unchanged
        await t.tap(find.text('Monthly'));
        await t.pump();
        expect(find.textContaining('days free'), findsNothing);
      });
    });
  }

  testWidgets('the phone layout is unchanged (canvas, not the tablet layout)', (
    t,
  ) async {
    await pump(t, _phone);
    expect(t.takeException(), isNull);
    expect(find.text('Continue'), findsOneWidget);
    // Phone keeps "Most Popular" on its own row above the title.
    final yearly = t.getRect(find.text('Yearly'));
    final pill = t.getRect(find.text('Most Popular'));
    expect(pill.bottom, lessThanOrEqualTo(yearly.top + 1));
  });

  testWidgets(
    'a short tablet window still fits (scrolls instead of overflowing)',
    (t) async {
      await pump(t, const Size(1024, 600));
      expect(t.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    },
  );

  group('which paywall each source opens', () {
    test('launch and subscription_lapsed open the plans paywall (View 2)', () {
      final splash = File(
        'lib/app/modules/splash/view/splash_view.dart',
      ).readAsStringSync();
      expect(splash.contains('PaywallView2'), isTrue);
      expect(splash.contains('Routes.PAYWALL'), isFalse);
      final home = File(
        'lib/app/modules/home/controller/home_controller.dart',
      ).readAsStringSync();
      final lapsed = RegExp(
        r"openPaywall\(\s*source: 'subscription_lapsed',\s*plans: true",
      ).hasMatch(home);
      expect(lapsed, isTrue);
    });

    test('only these sources still use the yearly pitch (View 1)', () {
      final src = File(
        'lib/app/modules/paywall/services/paywall_triggers.dart',
      ).readAsStringSync();
      final view1 = RegExp(
        r"(\w+)\('(\w+)', plans: false",
      ).allMatches(src).map((m) => m.group(2)).toSet();
      expect(view1, {'onboarding', 'scan_warning', 'scan_limit', 'ai_limit'});
    });
  });
}
