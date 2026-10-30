import 'package:ai_business_card_maker/app/core/services/store_links.dart';
import 'package:ai_business_card_maker/app/core/widgets/crown_upgrade_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  crownReduceMotion();
  test('store links: only valid http(s) addresses are accepted, nothing is invented', () {
    expect(StoreLinks.parse(''), isNull);
    expect(StoreLinks.parse('   '), isNull);
    expect(StoreLinks.parse('not a url'), isNull);
    expect(StoreLinks.parse('market://details?id=x'), isNull);
    expect(StoreLinks.parse('https://play.google.com/store/apps/details?id=a.b').toString(), 'https://play.google.com/store/apps/details?id=a.b');
    expect(StoreLinks.playStoreUrl, isEmpty, reason: 'no default address is built in');
    expect(StoreLinks.appStoreUrl, isEmpty);
    expect(StoreLinks.listing, isNull);
  });

  testWidgets('Rate App with no listing configured says so instead of failing', (t) async {
    await t.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    await StoreLinks.rateApp();
    await t.pump();
    expect(find.text('Not available yet'), findsOneWidget);
    await t.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('the shared crown keeps its tap action and wiggles', (t) async {
    var taps = 0;
    await t.pumpWidget(MaterialApp(home: Center(child: CrownUpgradeButton(size: 40, iconSize: 22, borderRadius: 12, onTap: () => taps++))));
    expect(t.getSize(find.byType(CrownUpgradeButton)), const Size(40, 40));
    final a = t.widget<Transform>(find.descendant(of: find.byType(CrownUpgradeButton), matching: find.byType(Transform)).first).transform.storage.toList();
    await t.pump(const Duration(milliseconds: 150));
    final b = t.widget<Transform>(find.descendant(of: find.byType(CrownUpgradeButton), matching: find.byType(Transform)).first).transform.storage.toList();
    expect(a, isNot(b), reason: 'it is rotating');
    await t.tap(find.byType(CrownUpgradeButton));
    expect(taps, 1);
  });
}

void crownReduceMotion() {
  testWidgets('with reduce-motion the crown stays still and the screen can settle', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpWidget(MaterialApp(home: Center(child: CrownUpgradeButton(onTap: () {}))));
    await t.pumpAndSettle();
  });
}
