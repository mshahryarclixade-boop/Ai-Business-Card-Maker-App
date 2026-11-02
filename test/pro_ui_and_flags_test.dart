import 'package:ai_business_card_maker/app/core/services/remote_config_service.dart';
import 'package:ai_business_card_maker/app/core/widgets/hide_when_pro.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/credit_config_model.dart';
import 'package:ai_business_card_maker/app/modules/splash/view/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Only [isUserPro] is used by HideWhenPro.
class _FakeSub extends GetxController implements SubscriptionController {
  @override
  final isUserPro = false.obs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Premium UI', () {
    tearDown(Get.reset);

    testWidgets('upgrade icons show for free users and disappear the moment they become Pro', (t) async {
      final sub = Get.put<SubscriptionController>(_FakeSub());
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: HideWhenPro(child: Icon(Icons.workspace_premium, key: Key('crown'))))));
      expect(find.byKey(const Key('crown')), findsOneWidget, reason: 'free: visible');
      sub.isUserPro.value = true; // a successful purchase or restore
      await t.pump();
      expect(find.byKey(const Key('crown')), findsNothing, reason: 'Pro: hidden');
      sub.isUserPro.value = false; // the subscription lapses
      await t.pump();
      expect(find.byKey(const Key('crown')), findsOneWidget, reason: 'free again: visible');
    });

    testWidgets('without a subscription controller (not set up yet) the icon stays visible', (t) async {
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: HideWhenPro(child: Icon(Icons.star, key: Key('c'))))));
      expect(find.byKey(const Key('c')), findsOneWidget);
    });
  });

  group('Remote Config onboarding switch', () {
    test('onboarding shows only on a first launch and only while the flag is on', () {
      expect(shouldShowOnboarding(seen: false, enabled: true), isTrue);
      expect(shouldShowOnboarding(seen: false, enabled: false), isFalse, reason: 'switched off: skipped');
      expect(shouldShowOnboarding(seen: true, enabled: true), isFalse, reason: 'already done');
      expect(shouldShowOnboarding(seen: true, enabled: false), isFalse);
    });

    test('before Remote Config has loaded (or if it failed) onboarding stays on, as before', () {
      expect(RemoteConfigService().onboardingEnabled, isTrue);
      expect(RemoteConfigService().creditsEnabled, isFalse);
    });
  });

  group('Credit costs per AI feature', () {
    test('costs come from the credit_costs JSON, default to free, and map every AI task', () {
      const d = CreditCosts();
      for (final t in ['coachReply', 'panelTurn', 'panelReport', 'buildProfile', 'rewrite', 'analyze', 'fixSuggestion', 'other']) {
        expect(d.forTask(t), 0, reason: 'free until configured');
      }
      final c = CreditCosts.fromJsonString('{"clixa":1,"career":2,"panel":3,"ai_card":1}');
      expect(c.forTask('coachReply'), 1);
      expect(c.forTask('analyze'), 2);
      expect(c.forTask('fixSuggestion'), 2);
      expect(c.forTask('panelTurn'), 3);
      expect(c.forTask('panelReport'), 3);
      expect(c.forTask('unknown'), 0);
      expect(CreditCosts.fromJsonString('not json').forTask('analyze'), 0);
    });
  });
}
