import 'dart:async';

import 'package:flutter/widgets.dart' show FakeAccessibilityFeatures, WidgetsBinding;
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_business_card_maker/app/modules/career_studio/service/career_ai_service.dart';

import 'package:ai_business_card_maker/app/modules/clixa/service/clixa_ai_service.dart';
import 'package:ai_business_card_maker/app/modules/clixa/service/clixa_chat_store.dart';

import 'package:ai_business_card_maker/app/core/services/permission_gate.dart';
import 'package:permission_handler/permission_handler.dart';

import 'fake_career_ai.dart';
import 'fake_clixa_ai.dart';

/// Every test file runs against the offline Career Studio and Clixa AIs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // No permission plugin in tests: everything is granted unless a test says
  // otherwise (see test/permission_gate_test.dart).
  PermissionGate.statusOf = (_) async => PermissionStatus.granted;
  PermissionGate.requestOf = (_) async => PermissionStatus.granted;
  ClixaChatStore.enabled = false; // no storage directory in tests
  CareerAi.instance = FakeCareerAi();
  ClixaAi.instance = FakeClixaAi();
  // The Pro crown wiggles forever (like Clixa's), so pumpAndSettle would never
  // finish on a screen that has one. Tests run with the device's reduce-motion
  // setting on, which keeps the crown still. A test that needs real page
  // transitions turns it off again (see test/email_signature_test.dart).
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });
  await testMain();
}
