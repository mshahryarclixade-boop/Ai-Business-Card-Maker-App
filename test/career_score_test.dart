import 'dart:io';

import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_score_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/generated_profile_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/profile_builder_flow_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_builder_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_draft_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/career_studio_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_fix_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_fixes_ready_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_new_score_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_report_view.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/ai_toolkit_section.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class _FakeSub extends SubscriptionController {
  @override
  void onInit() {}

  @override
  Future<bool> buy(
    BuildContext context, {
    required String productId,
    required String plan,
    required String source,
  }) async {
    isUserPro.value = true;
    return true;
  }
}

/// The report, the fix queue, "Fixes ready", the Pro re-scan and the score on
/// the Career Studio hub all read one saved score.
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

  late _FakeSub sub;

  Future<void> openHub(WidgetTester t, {bool pro = false}) async {
    Get.reset();
    await GetStorage().erase();
    CareerScoreStore.clear();
    GeneratedProfileStore.clear();
    ProfileBuilderDraftStore.clear();
    Get.put(ProfileStore());
    sub = _FakeSub();
    sub.isUserPro.value = pro;
    Get.put<SubscriptionController>(sub);
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      GetMaterialApp(home: const Scaffold(body: AiToolkitSection())),
    );
    await t.tap(find.text('Career Studio'));
    await t.pumpAndSettle();
  }

  Future<void> flush(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 50));
  }

  /// Hub -> Optimizer -> Analyze (pasted text) -> report.
  Future<void> scan(WidgetTester t) async {
    await t.tap(find.text('Profile Optimizer'));
    await t.pumpAndSettle();
    await t.tap(find.text('Paste sections by hand'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Designer with 5 years');
    await t.tap(find.text('Analyze my profile'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(seconds: 4));
    await t.pumpAndSettle();
    expect(find.byType(ProfileReportView), findsOneWidget);
  }

  /// [text] inside the screen of type [screen] (routes below stay mounted).
  Finder inScreen(Type screen, String text) =>
      find.descendant(of: find.byType(screen), matching: find.text(text));

  Future<void> useThis(WidgetTester t) async {
    await t.tap(find.text('Use this'));
    await t.pumpAndSettle();
  }

  testWidgets('hub shows the report\'s score and the spent scan', (t) async {
    await openHub(t);
    expect(find.textContaining('LinkedIn score'), findsNothing);
    expect(find.text('1 build · 1 scan left'), findsOneWidget);

    await scan(t);
    expect(inScreen(ProfileReportView, '54'), findsOneWidget); // report ring
    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();

    // Same 54 on the hub, nothing fixed yet; the free scan is used.
    expect(find.text('LinkedIn score: 54'), findsOneWidget);
    expect(find.text('0 of 7 fixes done · tap to continue'), findsOneWidget);
    expect(find.text('1 build · 0 scan left'), findsOneWidget);
    expect(find.text('USED'), findsOneWidget); // optimizer
    await flush(t);
  });

  testWidgets('Free: after the one build, Profile Builder opens the saved '
      'profile', (t) async {
    await openHub(t);
    GeneratedProfileStore.save((
      headline: 'Saved headline',
      about: 'Saved about',
      experience: 'Saved experience',
    ), 2);
    await t.pump();
    expect(find.text('USED'), findsOneWidget);

    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileDraftView), findsOneWidget);
    expect(find.byType(ProfileBuilderView), findsNothing);
    expect(find.text('Saved headline'), findsOneWidget);
    expect(find.text('2 REWRITES LEFT'), findsOneWidget);

    // Edits on that page are kept for next time.
    await t.tap(find.text('Rewrite').first);
    await t.pumpAndSettle();
    expect(GeneratedProfileStore.rewritesLeft, 1);
    expect(GeneratedProfileStore.texts!.headline, startsWith('Rewritten'));
    await flush(t);
  });

  testWidgets('Pro: Profile Builder still starts a new build', (t) async {
    await openHub(t, pro: true);
    GeneratedProfileStore.save((
      headline: 'Saved headline',
      about: 'a',
      experience: 'e',
    ), 3);
    await t.pump();
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileBuilderView), findsOneWidget);
    expect(find.byType(ProfileDraftView), findsNothing);
    await flush(t);
  });

  testWidgets('Free: fix queue -> Fixes ready -> save -> hub shows the '
      'expected score', (t) async {
    await openHub(t);
    await scan(t);

    await t.tap(find.text('Fix the 2 free issues'));
    await t.pumpAndSettle();
    expect(find.text('Fix 1 of 2'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    expect(
      inScreen(ProfileFixView, 'Headline is only a job title'),
      findsOneWidget,
    );
    await useThis(t);
    expect(find.text('Fix 2 of 2'), findsOneWidget);
    expect(inScreen(ProfileFixView, 'About is under 3 lines'), findsOneWidget);
    await useThis(t);

    // Fixes ready (Free): 54 -> 68 expected, upsell, no LinkedIn step.
    expect(find.byType(ProfileFixesReadyView), findsOneWidget);
    expect(inScreen(ProfileFixesReadyView, 'Fixes ready'), findsOneWidget);
    expect(
      inScreen(ProfileFixesReadyView, '2 fixes ready to add'),
      findsOneWidget,
    );
    expect(inScreen(ProfileFixesReadyView, '54'), findsOneWidget);
    expect(inScreen(ProfileFixesReadyView, '68'), findsOneWidget);
    expect(inScreen(ProfileFixesReadyView, 'expected'), findsOneWidget);
    expect(inScreen(ProfileFixesReadyView, '+8'), findsOneWidget);
    expect(inScreen(ProfileFixesReadyView, '+6'), findsOneWidget);
    expect(
      inScreen(ProfileFixesReadyView, '5 more fixes could take you to 90'),
      findsOneWidget,
    );
    expect(
      inScreen(ProfileFixesReadyView, 'Unlock all fixes with Pro'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ProfileFixesReadyView),
        matching: find.textContaining('LinkedIn'),
      ),
      findsNothing,
    );
    expect(inScreen(ProfileFixesReadyView, 'Re-scan my profile'), findsNothing);

    await t.tap(find.text('Save my fixes'));
    await t.pump();
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
    expect(find.text('LinkedIn score: 54'), findsOneWidget);
    expect(find.textContaining('About 68 after your fixes'), findsOneWidget);
    await t.pump(const Duration(seconds: 4)); // snackbar

    // Back in the report: ring is the scan's 54, "about 68" with the fixes.
    await t.tap(find.text('LinkedIn score: 54'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileReportView), findsOneWidget);
    expect(inScreen(ProfileReportView, '54'), findsOneWidget);
    expect(
      inScreen(ProfileReportView, 'With your fixes: about 68'),
      findsOneWidget,
    );
    expect(inScreen(ProfileReportView, 'Fixes · 2 of 7 done'), findsOneWidget);
    expect(inScreen(ProfileReportView, 'Done'), findsNWidgets(2));
    await flush(t);
  });

  testWidgets('skipping a fix leaves it out of "Fixes ready"', (t) async {
    await openHub(t);
    await scan(t);
    await t.tap(find.text('Fix the 2 free issues'));
    await t.pumpAndSettle();
    await t.tap(find.text('Skip for now'));
    await t.pumpAndSettle();
    expect(find.text('Fix 2 of 2'), findsOneWidget);
    await useThis(t);
    expect(
      inScreen(ProfileFixesReadyView, '1 fixes ready to add'),
      findsOneWidget,
    );
    expect(inScreen(ProfileFixesReadyView, '60'), findsOneWidget); // 54 + 6
    expect(
      inScreen(ProfileFixesReadyView, 'About is under 3 lines'),
      findsOneWidget,
    );
    expect(
      inScreen(ProfileFixesReadyView, 'Headline is only a job title'),
      findsNothing,
    );
    await flush(t);
  });

  testWidgets('Free: unlock from "Fixes ready" -> You\'re Pro -> the rest', (
    t,
  ) async {
    await openHub(t);
    await scan(t);
    await t.tap(find.text('Fix the 2 free issues'));
    await t.pumpAndSettle();
    await useThis(t);
    await useThis(t);

    await t.tap(find.text('Unlock all fixes with Pro'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text("You're Pro"), findsOneWidget);
    await t.tap(find.text('Continue to your fixes'));
    await t.pumpAndSettle();
    expect(find.text('Fix 1 of 5'), findsOneWidget);
    expect(inScreen(ProfileFixView, 'No Featured section'), findsOneWidget);
    expect(find.byType(ProfileFixesReadyView), findsNothing);
    await flush(t);
  });

  testWidgets('Pro: fix all 7 -> Fixes ready -> re-scan -> new score -> hub', (
    t,
  ) async {
    await openHub(t, pro: true);
    await scan(t);
    expect(find.text('Fix all 7 issues'), findsOneWidget);
    await t.tap(find.text('Fix all 7 issues'));
    await t.pumpAndSettle();
    for (var i = 1; i <= 7; i++) {
      expect(find.text('Fix $i of 7'), findsOneWidget, reason: 'step $i');
      await useThis(t);
    }

    // Fixes ready (Pro): 54 -> 90 expected, no upsell.
    expect(
      inScreen(ProfileFixesReadyView, '7 fixes ready to add'),
      findsOneWidget,
    );
    expect(inScreen(ProfileFixesReadyView, '90'), findsOneWidget);
    expect(
      inScreen(ProfileFixesReadyView, 'Unlock all fixes with Pro'),
      findsNothing,
    );
    expect(
      inScreen(ProfileFixesReadyView, 'Profile link has random numbers'),
      findsOneWidget,
    );
    expect(
      inScreen(ProfileFixesReadyView, 'Re-scan my profile'),
      findsOneWidget,
    );
    expect(inScreen(ProfileFixesReadyView, 'Back to report'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProfileFixesReadyView),
        matching: find.textContaining('LinkedIn'),
      ),
      findsNothing,
    );

    // Before the re-scan the hub is not updated.
    await t.tap(find.text('Re-scan my profile'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Re-scanning your updated profile'), findsOneWidget);
    expect(find.text('Takes about 15 seconds'), findsOneWidget);
    await t.pump(const Duration(seconds: 3)); // the 2.8s wait ends
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpAndSettle();

    // Your new score: before 54 -> now 90, +36, every fix listed.
    expect(find.byType(ProfileNewScoreView), findsOneWidget);
    expect(inScreen(ProfileNewScoreView, 'Your new score'), findsOneWidget);
    expect(inScreen(ProfileNewScoreView, '54'), findsOneWidget);
    expect(inScreen(ProfileNewScoreView, '90'), findsOneWidget);
    expect(inScreen(ProfileNewScoreView, 'before'), findsOneWidget);
    expect(inScreen(ProfileNewScoreView, 'now'), findsOneWidget);
    expect(inScreen(ProfileNewScoreView, '+36 POINTS'), findsOneWidget);
    expect(
      find.text('Saved to your progress. Check back any time.'),
      findsOneWidget,
    );
    for (final n in [
      'Headline',
      'About',
      'Featured',
      'Experience',
      'Skills',
      'Banner',
      'Profile link',
    ]) {
      expect(inScreen(ProfileNewScoreView, n), findsOneWidget, reason: n);
    }

    await t.tap(find.text('Back to Career Studio'));
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
    expect(find.byType(ProfileNewScoreView), findsNothing);
    expect(find.text('LinkedIn score: 90'), findsOneWidget);
    expect(find.text('Up from 54 · tap to see the report'), findsOneWidget);
    expect(find.text('Pro plan'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);

    // The report agrees with the hub.
    await t.tap(find.text('LinkedIn score: 90'));
    await t.pumpAndSettle();
    expect(inScreen(ProfileReportView, '90'), findsOneWidget);
    expect(inScreen(ProfileReportView, 'LOOKING GOOD'), findsOneWidget);
    expect(inScreen(ProfileReportView, 'Fixes · 7 of 7 done'), findsOneWidget);
    expect(inScreen(ProfileReportView, 'Done'), findsNWidgets(7));
    expect(inScreen(ProfileReportView, 'See your fixes'), findsOneWidget);
    await flush(t);
  });

  testWidgets('a new scan starts the report over', (t) async {
    await openHub(t, pro: true);
    await scan(t);
    await t.tap(find.text('Fix all 7 issues'));
    await t.pumpAndSettle();
    await useThis(t);
    expect(CareerScoreStore.done.length, 1);
    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();
    expect(find.text('Fixes · 1 of 7 done'), findsOneWidget);
    expect(find.byType(ProfileFixView), findsNothing);

    // Back to the hub, scan again: 0 done.
    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Profile Optimizer'));
    await t.pumpAndSettle();
    await t.tap(find.text('Paste sections by hand'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Designer');
    await t.tap(find.text('Analyze my profile'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(seconds: 4));
    await t.pumpAndSettle();
    expect(find.text('Fixes · 0 of 7 done'), findsOneWidget);
    expect(CareerScoreStore.done, isEmpty);
    await flush(t);
  });
}
