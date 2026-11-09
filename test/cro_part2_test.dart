import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/analytics_service.dart';
import 'package:ai_business_card_maker/app/core/services/permission_gate.dart';
import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_optimizer_view.dart';
import 'package:ai_business_card_maker/app/modules/contacts/controller/contacts_controller.dart';
import 'package:ai_business_card_maker/app/modules/contacts/view/add_contact_view.dart';
import 'package:ai_business_card_maker/app/modules/main_nav/controller/main_nav_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/paywall_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/paywall_triggers.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/view/first_card_ready_view.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/onboarding_experiment.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/view/scan_card_view.dart';
import 'package:ai_business_card_maker/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fonts.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}
}

const _sizes = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 393x852': Size(393, 852),
  'tablet 820x1180': Size(820, 1180),
  'tablet landscape 1180x820': Size(1180, 820),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Sub sub;
  late List<(String, Map<String, Object>)> events;

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
    events = [];
    AnalyticsService.sink = (n, p) => events.add((n, p));
    sub = _Sub();
    Get.put<SubscriptionController>(sub);
    Get.put(ProfileStore());
  });

  tearDown(() {
    AnalyticsService.sink = null;
    PermissionGate.statusOf = (_) async => PermissionStatus.granted;
    PermissionGate.requestOf = (_) async => PermissionStatus.granted;
  });

  void size(WidgetTester t, Size s) {
    t.view.physicalSize = s * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  // ---------------------------------------------------------------- paywall
  group('Paywall (plans screen)', () {
    Future<void> pumpPaywall(WidgetTester t, Size s) async {
      size(t, s);
      await t.pumpWidget(const GetMaterialApp(home: PaywallView2()));
      await t.pump(const Duration(milliseconds: 300));
    }

    testWidgets('new copy, correct saving, no sparkle, no 70%', (t) async {
      await pumpPaywall(t, _sizes['phone 393x852']!);
      expect(find.text('Create and scan without limits'), findsOneWidget);
      expect(
        find.text('Get unlimited access to every feature'),
        findsOneWidget,
      );
      for (final chip in const [
        'Unlimited AI cards',
        'Unlimited scans',
        'No watermark',
        'All templates and QR styles',
      ]) {
        expect(find.text(chip), findsOneWidget, reason: chip);
      }
      expect(
        find.text('QR Generator'),
        findsNothing,
      ); // the old 6 chips are gone
      expect(find.text('50+ Templates'), findsNothing);

      // Yearly $29.99 ($2.50/month, billed yearly); monthly $6.99; the real saving.
      expect(find.text(r'$29.99'), findsOneWidget);
      expect(find.text('/year'), findsOneWidget);
      expect(find.text(r'$2.50/month, billed yearly'), findsOneWidget);
      expect(find.text(r'$6.99'), findsOneWidget);
      expect(find.text('Save 64%'), findsOneWidget);
      expect(find.textContaining('70'), findsNothing);
      // 29.99 vs 12 x 6.99 really is a 64% saving.
      expect(((1 - 29.99 / (6.99 * 12)) * 100).round(), 64);

      // Not a trial user: "Continue", and the sparkle on the button is gone.
      expect(find.text('Continue'), findsOneWidget);
      expect(find.textContaining('free'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets); // artwork sparkles
      final button = find.ancestor(
        of: find.text('Continue'),
        matching: find.byType(InkWell),
      );
      expect(
        find.descendant(of: button, matching: find.byIcon(Icons.auto_awesome)),
        findsNothing,
      );

      // No discount on the default paywall.
      expect(find.textContaining(r'$19.99'), findsNothing);
      expect(find.textContaining('off'), findsNothing);
    });

    testWidgets('the button is always "Continue"; the trial is in the fine print',
        (t) async {
      // Not eligible: plain commitment line, no trial wording.
      await pumpPaywall(t, _sizes['phone 393x852']!);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('No commitment, cancel anytime'), findsOneWidget);
      expect(find.textContaining('days free'), findsNothing);
      await t.pumpWidget(const SizedBox());

      // Eligible: the yearly plan explains the trial with the store price.
      sub.yearlyTrialEligible.value = true;
      sub.yearlyTrialDays.value = 3;
      await pumpPaywall(t, _sizes['phone 393x852']!);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Try 3 days free'), findsNothing);
      expect(
        find.text(r'3 days free, then $29.99/year. Cancel anytime.'),
        findsOneWidget,
      );

      // Monthly has no trial.
      await t.tap(find.text('Monthly'));
      await t.pump();
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('No commitment, cancel anytime'), findsOneWidget);
      await t.tap(find.text('Yearly'));
      await t.pump();
      expect(find.textContaining('3 days free'), findsOneWidget);
    });

    testWidgets('trial length follows the store, not a fixed number', (
      t,
    ) async {
      sub.yearlyTrialEligible.value = true;
      sub.yearlyTrialDays.value = 7;
      await pumpPaywall(t, _sizes['phone 393x852']!);
      expect(find.textContaining('7 days free, then'), findsOneWidget);
    });

    testWidgets('close button is visible at once; footer links are clear', (
      t,
    ) async {
      await pumpPaywall(t, _sizes['phone 393x852']!);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Restore Purchase'), findsOneWidget);
      expect(find.text('Term Of Use'), findsNothing); // the typo
      // The footer text is no longer tiny (it was 9pt).
      final style = t.widget<Text>(find.text('Terms of Use')).style!;
      expect(style.fontSize, greaterThanOrEqualTo(12));
    });

    testWidgets('a trigger headline replaces the default', (t) async {
      // ai_limit: "Unlimited AI cards" (Part 1) still wins over the default.
      size(t, _sizes['phone 393x852']!);
      await t.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (_) => TextButton(
              onPressed: () => PaywallTriggers.show(PaywallTrigger.proTemplate),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(find.byType(PaywallView2), findsOneWidget);
      expect(find.text('Create and scan without limits'), findsOneWidget);
    });

    for (final s in _sizes.entries) {
      testWidgets('both paywall screens fit on ${s.key}', (t) async {
        await pumpPaywall(t, s.value);
        expect(t.takeException(), isNull);
        expect(find.text('Continue'), findsOneWidget);
        await t.pumpWidget(const GetMaterialApp(home: PaywallView()));
        await t.pump(const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
      });
    }

    test('the saving text uses the real saving in any script', () {
      // Defaults: 29.99 vs 6.99 x 12 = 64%; never the old 70%.
      final y = PaywallConfig.defaults.yearly;
      expect(y.saveBadge, 'Save 64%');
      expect(y.perMonthNote, r'$2.50/month, billed yearly');
      expect(y.originalPrice, r'$83.88/year'); // 12 x 6.99, a true figure
    });
  });

  // -------------------------------------------------------- first card ready
  group('First card experience', () {
    Future<void> pumpFirst(WidgetTester t, Size s) async {
      size(t, s);
      // The control group: no paywall in the way of the test.
      GetStorage().write(OnboardingExperiment.storageKey, 'control');
      await t.pumpWidget(
        GetMaterialApp(
          home: const FirstCardReadyView(),
          getPages: [
            GetPage(
              name: Routes.MAIN,
              page: () => const Scaffold(body: Text('HOME')),
            ),
          ],
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
    }

    testWidgets('two CTAs: Scan a Card and Share Your Card', (t) async {
      await pumpFirst(t, _sizes['phone 393x852']!);
      expect(find.text('Scan a Card'), findsOneWidget);
      expect(find.text('Share Your Card'), findsOneWidget);
      expect(find.text('Go to Home'), findsNothing);
    });

    testWidgets('Scan a Card goes Home with the scan queued', (t) async {
      MainNavController.pendingFirstCardAction = null;
      await pumpFirst(t, _sizes['phone 393x852']!);
      await t.tap(find.text('Scan a Card'));
      await t.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(MainNavController.pendingFirstCardAction, FirstCardNext.scan);
    });

    testWidgets('Share Your Card goes Home with sharing queued', (t) async {
      MainNavController.pendingFirstCardAction = null;
      Get.put(RecentDesignsService()).designs.add(
        RecentDesign(
          id: '1',
          path: 'x.png',
          savedAt: DateTime(2025),
          title: 'Card',
          designData: const {},
        ),
      );
      await pumpFirst(t, _sizes['phone 393x852']!);
      await t.tap(find.text('Share Your Card'));
      await t.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(MainNavController.pendingFirstCardAction, FirstCardNext.share);
    });

    test('the onboarding paywall test still applies before Home', () {
      GetStorage().write(OnboardingExperiment.storageKey, 'paywall');
      expect(OnboardingExperiment().showsPaywall, isTrue);
      GetStorage().write(OnboardingExperiment.storageKey, 'control');
      expect(OnboardingExperiment().showsPaywall, isFalse);
    });

    for (final s in _sizes.entries) {
      testWidgets('fits on ${s.key}', (t) async {
        await pumpFirst(t, s.value);
        expect(t.takeException(), isNull);
        expect(find.text('Scan a Card'), findsOneWidget);
      });
    }
  });

  // ------------------------------------------------------------- scan screen
  group('Scan screen', () {
    Future<void> pumpScan(WidgetTester t, Size s) async {
      size(t, s);
      await t.pumpWidget(const GetMaterialApp(home: ScanCardView()));
      await t.pump(const Duration(milliseconds: 400));
    }

    testWidgets('Auto-detect by default; the orientation toggle is hidden', (
      t,
    ) async {
      await pumpScan(t, _sizes['phone 393x852']!);
      expect(find.text('Landscape'), findsNothing);
      expect(find.text('Portrait'), findsNothing);
      expect(find.text('Auto'), findsNothing);
      expect(find.text('Auto-detecting card...'), findsOneWidget);
    });

    testWidgets('an explanation comes before the camera prompt', (t) async {
      var asked = 0;
      PermissionGate.statusOf = (_) async => PermissionStatus.denied;
      PermissionGate.requestOf = (_) async {
        asked++;
        return PermissionStatus.denied;
      };
      await pumpScan(t, _sizes['phone 393x852']!);
      expect(find.text('Allow camera access'), findsOneWidget);
      expect(find.textContaining('scan business cards'), findsOneWidget);
      expect(asked, 0); // nothing was requested yet

      await t.tap(find.text('Continue'));
      await t.pump(const Duration(milliseconds: 300));
      expect(asked, 1); // now the system prompt
      expect(find.text('Allow camera access'), findsNothing);
    });

    testWidgets('denied: Open Settings is offered', (t) async {
      var opened = 0;
      PermissionGate.openSettings = () async {
        opened++;
        return true;
      };
      PermissionGate.statusOf = (_) async => PermissionStatus.permanentlyDenied;
      PermissionGate.requestOf = (_) async =>
          PermissionStatus.permanentlyDenied;
      await pumpScan(t, _sizes['phone 393x852']!);
      await t.tap(find.text('Continue'));
      await t.pump(const Duration(milliseconds: 600));

      // The system will not ask again: the Open Settings / Later dialog.
      expect(find.text('Open Settings'), findsOneWidget);
      await t.tap(find.text('Later'));
      await t.pump(const Duration(milliseconds: 600));

      // ...and the screen keeps an Open Settings button.
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      await t.tap(find.text('Open Settings'));
      await t.pump();
      expect(opened, 1);
    });

    testWidgets('already allowed: straight to the camera, no explanation', (
      t,
    ) async {
      await pumpScan(t, _sizes['phone 393x852']!);
      expect(find.text('Allow camera access'), findsNothing);
    });

    for (final s in _sizes.entries) {
      testWidgets('fits on ${s.key} (explanation and denied states)', (
        t,
      ) async {
        PermissionGate.statusOf = (_) async => PermissionStatus.denied;
        PermissionGate.requestOf = (_) async => PermissionStatus.denied;
        await pumpScan(t, s.value);
        expect(t.takeException(), isNull);
        await t.tap(find.text('Continue'));
        await t.pump(const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
        expect(find.text('Open Settings'), findsOneWidget);
      });
    }
  });

  // ------------------------------------------------------------ add contact
  group('Add contact', () {
    late ContactsController contacts;

    Future<void> pumpAdd(WidgetTester t, Size s) async {
      size(t, s);
      contacts = Get.put(ContactsController(), tag: 'contacts');
      await t.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(
                onPressed: () => Get.to(() => const AddContactView()),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    Future<void> fill(WidgetTester t, String label, String value) async {
      final f = find.widgetWithText(TextFormField, label).first;
      await t.ensureVisible(f);
      await t.enterText(f, value);
    }

    Future<void> save(WidgetTester t) async {
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
    }

    testWidgets('nothing marked required except name or email', (t) async {
      await pumpAdd(t, _sizes['phone 393x852']!);
      expect(find.text('First Name *'), findsNothing);
      expect(find.text('Company Name *'), findsNothing);
      expect(find.textContaining('*'), findsNothing);
    });

    testWidgets('empty form: asks for a name or an email, saves nothing', (
      t,
    ) async {
      await pumpAdd(t, _sizes['phone 393x852']!);
      await save(t);
      expect(find.text('Add a name or an email'), findsWidgets);
      expect(contacts.contacts, isEmpty);
    });

    testWidgets('only a name is enough (no company)', (t) async {
      await pumpAdd(t, _sizes['phone 393x852']!);
      await fill(t, 'First Name', 'Sara');
      await save(t);
      expect(contacts.contacts.single.firstName, 'Sara');
      expect(contacts.contacts.single.companyName, '');
    });

    testWidgets('only an email is enough (no name, no company)', (t) async {
      await pumpAdd(t, _sizes['phone 393x852']!);
      await fill(t, 'someone@email.com', 'sara@example.com');
      await save(t);
      expect(contacts.contacts.single.email, 'sara@example.com');
      expect(contacts.contacts.single.firstName, '');
    });

    testWidgets(
      'a company alone is not enough; a bad email is still rejected',
      (t) async {
        await pumpAdd(t, _sizes['phone 393x852']!);
        await fill(t, 'Company Name', 'Acme');
        await save(t);
        expect(contacts.contacts, isEmpty);
        expect(find.text('Add a name or an email'), findsWidgets);
      },
    );

    for (final s in _sizes.entries) {
      testWidgets('fits on ${s.key}', (t) async {
        await pumpAdd(t, s.value);
        await save(t);
        expect(t.takeException(), isNull);
      });
    }
  });

  // ------------------------------------------------------------- home + more
  group('Home and Profile Optimizer', () {
    test('Home no longer has the two top buttons; the toolkit stays below', () {
      final src = File(
        'lib/app/modules/home/view/home_view.dart',
      ).readAsStringSync();
      expect(src.contains('HomeQuickActions'), isFalse);
      expect(src.indexOf('MyCardSection()'), lessThan(src.indexOf('AiToolkitSection()')));
      expect(
        File('lib/app/modules/home/widgets/home_quick_actions.dart').existsSync(),
        isFalse,
      );
    });

    testWidgets('Profile Optimizer shows what can be uploaded', (t) async {
      size(t, _sizes['phone 393x852']!);
      await t.pumpWidget(const GetMaterialApp(home: ProfileOptimizerView()));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Supported uploads'), findsOneWidget);
      expect(find.textContaining('LinkedIn profile PDF'), findsOneWidget);
      expect(
        find.textContaining('Screenshots of your profile'),
        findsOneWidget,
      );
    });

    for (final s in _sizes.entries) {
      testWidgets('Profile Optimizer fits on ${s.key}', (t) async {
        size(t, s.value);
        await t.pumpWidget(const GetMaterialApp(home: ProfileOptimizerView()));
        await t.pump(const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
        expect(find.text('Supported uploads'), findsOneWidget);
      });
    }
  });
}
