import 'dart:async';

import 'package:ai_business_card_maker/app/modules/career_studio/service/career_ai_service.dart';

import 'package:ai_business_card_maker/app/modules/clixa/service/clixa_ai_service.dart';
import 'package:ai_business_card_maker/app/modules/clixa/service/clixa_chat_store.dart';

import 'fake_career_ai.dart';
import 'fake_clixa_ai.dart';

/// Every test file runs against the offline Career Studio and Clixa AIs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ClixaChatStore.enabled = false; // no storage directory in tests
  CareerAi.instance = FakeCareerAi();
  ClixaAi.instance = FakeClixaAi();
  await testMain();
}
