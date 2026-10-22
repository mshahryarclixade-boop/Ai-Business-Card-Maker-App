import 'dart:io';

import 'package:ai_business_card_maker/app/modules/career_studio/controller/profile_builder_flow_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_score_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/generated_profile_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/career_studio_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_builder_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_draft_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_optimizer_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_report_view.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/ai_toolkit_section.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/model/user_profile_data.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Career Studio fixes: field behaviour, saved builder draft, back to the
/// hub, PDF help sheet, premium sheet and right-to-left transitions.
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
    ProfileBuilderDraftStore.clear();
    CareerScoreStore.clear();
    GeneratedProfileStore.clear();
    Get.put(ProfileStore());
    ProfileStore.to.profile.value = const UserProfileData(
      fullName: 'ayesha raza',
      designation: 'Product Designer',
      companyName: 'Northwind Studio',
    );
  });

  /// Home toolkit -> Career Studio, the way the app reaches the hub.
  Future<void> openHub(WidgetTester t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      GetMaterialApp(home: const Scaffold(body: AiToolkitSection())),
    );
    await t.tap(find.text('Career Studio'));
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
  }

  Future<void> next(WidgetTester t) async {
    await t.tap(find.byType(ElevatedButton));
    await t.pumpAndSettle();
  }

  testWidgets('1. builder fields capitalise and Next walks to the last', (
    t,
  ) async {
    await openHub(t);
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();

    final fields = t.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.length, 4);
    for (final f in fields) {
      expect(f.textCapitalization, TextCapitalization.words);
    }
    expect(fields[0].textInputAction, TextInputAction.next);
    expect(fields[1].textInputAction, TextInputAction.next);
    expect(fields[2].textInputAction, TextInputAction.next);
    expect(fields[3].textInputAction, TextInputAction.done); // last

    // Pressing Next on the keyboard moves down the fields.
    FocusNode? focused() => FocusManager.instance.primaryFocus;
    await t.tap(find.byType(TextField).at(0));
    await t.pump();
    final first = focused();
    for (var i = 1; i < 4; i++) {
      await t.testTextInput.receiveAction(TextInputAction.next);
      await t.pump();
      expect(focused(), isNot(first), reason: 'moved to field $i');
      final field = t.widget<EditableText>(
        find.descendant(
          of: find.byType(TextField).at(i),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.focusNode.hasFocus, isTrue, reason: 'field $i focused');
    }

    // Step 3's free text starts sentences with a capital.
    await t.testTextInput.receiveAction(TextInputAction.done);
    await next(t);
    await next(t);
    final wins = t.widget<TextField>(find.byType(TextField));
    expect(wins.textCapitalization, TextCapitalization.sentences);
  });

  testWidgets('3. leaving midway saves a draft the hub can resume', (t) async {
    await openHub(t);
    expect(find.text('Finish building your profile'), findsNothing);

    // Leaving untouched keeps nothing.
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pumpAndSettle();
    await t.tap(find.text('Leave'));
    await t.pumpAndSettle();
    expect(find.text('Finish building your profile'), findsNothing);

    // Go to step 2, pick a goal, leave.
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    await next(t);
    await t.tap(find.text('Get hired'));
    await t.pump();
    // Step 2 shows a back arrow, not a close: use the system back instead.
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Leave the builder?'), findsOneWidget);
    await t.tap(find.text('Leave'));
    await t.pumpAndSettle();

    expect(find.byType(CareerStudioView), findsOneWidget);
    expect(find.text('Finish building your profile'), findsOneWidget);
    expect(find.text('You stopped at step 2 of 3'), findsOneWidget);
    expect(ProfileBuilderDraftStore.hasDraft.value, isTrue);

    // Continue resumes on step 2 with the answer kept.
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.text('Who should find you?'), findsOneWidget);
    expect(Get.find<ProfileBuilderFlowController>().goal.value, 'Get hired');
  });

  testWidgets('3b. generating the profile clears the saved draft', (t) async {
    await openHub(t);
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    await next(t);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    await t.tap(find.text('Leave'));
    await t.pumpAndSettle();
    expect(ProfileBuilderDraftStore.hasDraft.value, isTrue);

    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    await next(t);
    await t.tap(find.text('Generate my profile'));
    await t.pump(const Duration(milliseconds: 300));
    expect(ProfileBuilderDraftStore.hasDraft.value, isFalse);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
  });

  testWidgets('2. back from the new profile goes straight to Career Studio', (
    t,
  ) async {
    await openHub(t);
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    await next(t);
    await next(t);
    await t.tap(find.text('Generate my profile'));
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.byType(ProfileDraftView), findsOneWidget);

    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
    expect(find.byType(ProfileDraftView), findsNothing);
    expect(find.byType(ProfileBuilderView), findsNothing);
  });

  testWidgets('2b. system back from the new profile does the same', (t) async {
    await openHub(t);
    await t.tap(find.text('Profile Builder'));
    await t.pumpAndSettle();
    await next(t);
    await next(t);
    await t.tap(find.text('Generate my profile'));
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
    expect(find.byType(ProfileDraftView), findsNothing);
  });

  testWidgets('4. Choose PDF opens the "Get your profile as a PDF" sheet', (
    t,
  ) async {
    await openHub(t);
    await t.tap(find.text('Profile Optimizer'));
    await t.pumpAndSettle();
    await t.tap(find.text('Choose PDF file'));
    await t.pumpAndSettle();
    expect(find.text('Get your profile as a PDF'), findsOneWidget);
    expect(
      find.textContaining('Open your profile in the LinkedIn app'),
      findsOneWidget,
    );
    expect(
      find.textContaining('under your name', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('save it to Files', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Choose file'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('Get your profile as a PDF'), findsNothing);
  });

  /// Live screens watch app-wide state; unmount them so GetX's cleanup timers
  /// don't outlive the test.
  Future<void> flush(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 50));
  }

  /// Optimizer -> Analyze (pasted text) -> report.
  Future<void> openReport(WidgetTester t) async {
    await openHub(t);
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

  testWidgets('5. back from the report goes straight to Career Studio', (
    t,
  ) async {
    await openReport(t);
    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
    expect(find.byType(ProfileReportView), findsNothing);
    expect(find.byType(ProfileOptimizerView), findsNothing);
    await flush(t);
  });

  testWidgets('5b. system back from the report does the same', (t) async {
    await openReport(t);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(CareerStudioView), findsOneWidget);
    expect(find.byType(ProfileOptimizerView), findsNothing);
    await flush(t);
  });

  testWidgets('6. "Fix all 7 with Pro" opens the premium bottom sheet', (
    t,
  ) async {
    await openReport(t);
    await t.tap(find.text('Fix all 7 with Pro'));
    await t.pumpAndSettle();
    expect(find.text('Unlock everything in Career Studio'), findsOneWidget);
    expect(find.text('GO PRO'), findsOneWidget);
    await t.tap(find.text('Not now'));
    await t.pumpAndSettle();
    expect(find.byType(ProfileReportView), findsOneWidget);
    await flush(t);
  });

  testWidgets('7. new Career Studio screens slide in from the right', (
    t,
  ) async {
    await openHub(t);
    double dx(Type type) => t.getTopLeft(find.byType(type)).dx;

    // Builder from the hub.
    await t.tap(find.text('Profile Builder'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    expect(dx(ProfileBuilderView), greaterThan(0), reason: 'mid-slide');
    await t.pumpAndSettle();
    expect(dx(ProfileBuilderView), 0);

    // Loading -> new profile (replaces the loading screen).
    await next(t);
    await next(t);
    await t.tap(find.text('Generate my profile'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Writing your profile'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 2900)); // last step -> navigate
    await t.pump(const Duration(milliseconds: 80));
    expect(dx(ProfileDraftView), greaterThan(0), reason: 'draft slides in');
    await t.pumpAndSettle();
    expect(dx(ProfileDraftView), 0);
    await flush(t);
  });

  testWidgets('7b. report slides in from the right after analyzing', (t) async {
    await openHub(t);
    await t.tap(find.text('Profile Optimizer'));
    await t.pumpAndSettle();
    await t.tap(find.text('Paste sections by hand'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Designer');
    await t.tap(find.text('Analyze my profile'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 2500)); // timer fires at 2.8s
    await t.pump(const Duration(milliseconds: 380));
    await t.pump(const Duration(milliseconds: 80));
    expect(find.byType(ProfileReportView), findsOneWidget);
    expect(
      t.getTopLeft(find.byType(ProfileReportView)).dx,
      greaterThan(0),
      reason: 'report slides in',
    );
    await t.pumpAndSettle();
    await flush(t);
  });
}
