import 'dart:io';

import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_score_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/profile_draft_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/profile_report_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/service/career_ai_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'fake_career_ai.dart';

void main() {
  late FakeCareerAi ai;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
  });

  setUp(() {
    Get.testMode = true;
    ai = FakeCareerAi();
    CareerAi.instance = ai;
    CareerScoreStore.clear();
  });

  group('Profile Builder / draft rewrite', () {
    test(
      'rewrite replaces the section text and uses one free rewrite',
      () async {
        final c = ProfileDraftController(isPro: false);
        c.load({DraftSection.about: 'Original about'});
        await c.rewrite(
          DraftSection.about,
          (cur) => CareerAi.instance.rewrite(section: 'about', text: cur),
        );
        expect(c.texts[DraftSection.about]!.value, contains('Original about'));
        expect(
          c.texts[DraftSection.about]!.value,
          startsWith('Rewritten about'),
        );
        expect(c.rewritesLeft.value, ProfileDraftController.freeRewrites - 1);
        expect(c.busy, isEmpty);
      },
    );

    test('a failed rewrite keeps the text and costs nothing', () async {
      final c = ProfileDraftController(isPro: false);
      c.load({DraftSection.headline: 'Keep me'});
      ai.error = const GeminiException('boom');
      await expectLater(
        c.rewrite(
          DraftSection.headline,
          (cur) => CareerAi.instance.rewrite(section: 'headline', text: cur),
        ),
        throwsA(isA<GeminiException>()),
      );
      expect(c.texts[DraftSection.headline]!.value, 'Keep me');
      expect(c.rewritesLeft.value, ProfileDraftController.freeRewrites);
      expect(c.busy, isEmpty);
    });

    test('Pro rewrites are not counted', () async {
      final c = ProfileDraftController(isPro: true);
      c.load({DraftSection.about: 'x'});
      await c.rewrite(
        DraftSection.about,
        (cur) => CareerAi.instance.rewrite(section: 'about', text: cur),
      );
      expect(c.rewritesLeft.value, ProfileDraftController.freeRewrites);
    });
  });

  group('Fix suggestions', () {
    test('first suggestion is free, Try another costs one', () async {
      final c = ProfileReportController(isPro: false);
      final fix = kReportFixes.first;
      await c.loadSuggestion(fix, current: 'Designer', issue: 'Short');
      expect(c.textFor(fix).value, 'AI suggestion 1 for headline');
      expect(c.rewritesLeft.value, ProfileReportController.freeRewrites);

      expect(
        await c.tryAnother(fix, current: 'Designer', issue: 'Short'),
        isTrue,
      );
      expect(c.textFor(fix).value, 'AI suggestion 2 for headline');
      expect(c.rewritesLeft.value, ProfileReportController.freeRewrites - 1);
    });

    test('a failed Try another costs nothing and keeps the text', () async {
      final c = ProfileReportController(isPro: false);
      final fix = kReportFixes.first;
      await c.loadSuggestion(fix, current: 'x', issue: 'y');
      ai.error = const GeminiException('boom');
      await expectLater(
        c.tryAnother(fix, current: 'x', issue: 'y'),
        throwsA(isA<GeminiException>()),
      );
      expect(c.textFor(fix).value, 'AI suggestion 1 for headline');
      expect(c.rewritesLeft.value, ProfileReportController.freeRewrites);
      expect(c.loading, isEmpty);
    });

    test('no rewrites left: no AI call', () async {
      final c = ProfileReportController(isPro: false, rewritesLeft: 0);
      final fix = kReportFixes.first;
      expect(await c.tryAnother(fix, current: 'x', issue: 'y'), isFalse);
      expect(ai.calls, 0);
    });
  });

  group('Scan and score breakdown', () {
    test('the score is the average of the analysed parts', () async {
      final a = await CareerAi.instance.analyze(const ProfileScanInput());
      CareerScoreStore.newScan(a);
      expect(CareerScoreStore.base.value, 54);
      expect(CareerScoreStore.partScore('headline'), 50);
      expect(CareerScoreStore.currentText['about'], 'Current about');
    });

    test(
      'accepting a fix raises that part, the banner fix raises photo',
      () async {
        CareerScoreStore.newScan(
          await CareerAi.instance.analyze(const ProfileScanInput()),
        );
        CareerScoreStore.markDone('headline');
        CareerScoreStore.markDone('banner');
        expect(CareerScoreStore.partScore('headline'), 90);
        expect(CareerScoreStore.partScore('photo'), 90);
        expect(CareerScoreStore.partScore('about'), 50); // untouched
        // A part already above the fixed score is never lowered.
        CareerScoreStore.markDone('experience');
        expect(CareerScoreStore.partScore('experience'), 90);
      },
    );

    test('a new scan starts the breakdown over', () async {
      final a = await CareerAi.instance.analyze(const ProfileScanInput());
      CareerScoreStore.newScan(a);
      CareerScoreStore.markDone('headline');
      CareerScoreStore.newScan(a);
      expect(CareerScoreStore.partScore('headline'), 50);
    });

    test('without an analysis the placeholder score is used', () {
      CareerScoreStore.newScan();
      expect(CareerScoreStore.base.value, CareerScoreStore.firstScan);
      expect(CareerScoreStore.partScores, isEmpty);
    });
  });
}
