import 'package:ai_business_card_maker/app/modules/profile_setup/widgets/profile_step_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  Future<void> open(WidgetTester t, {Object? args}) async {
    Get.reset();
    await t.pumpWidget(const GetMaterialApp(home: Scaffold()));
    Get.to(
      () => const Scaffold(body: ProfileBackButton()),
      arguments: args,
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }

  testWidgets('no back button when reached from onboarding', (t) async {
    await open(t);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('back button when opened from Home, and goes back to Home', (t) async {
    await open(t, args: profileSetupFromHome);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(ProfileBackButton), findsNothing);
  });
}
