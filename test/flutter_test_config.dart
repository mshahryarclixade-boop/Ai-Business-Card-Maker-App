import 'dart:async';

import 'package:ai_business_card_maker/app/modules/career_studio/service/career_ai_service.dart';

import 'fake_career_ai.dart';

/// Every test file runs against the offline Career Studio AI.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  CareerAi.instance = FakeCareerAi();
  await testMain();
}
