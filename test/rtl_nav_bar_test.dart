import 'package:ai_business_card_maker/app/modules/main_nav/widgets/main_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<double> _indicatorCenterX(
  WidgetTester t,
  TextDirection dir,
  int index,
) async {
  await t.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: dir,
        child: Scaffold(
          body: Center(
            child: MainBottomNavBar(currentIndex: index, onTabSelected: (_) {}),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  final bar = t.getRect(find.byType(MainBottomNavBar));
  final ind = t.getRect(find.byType(AnimatedPositionedDirectional));
  // Position of the pill relative to the bar's left edge.
  return ind.center.dx - bar.left;
}

void main() {
  testWidgets('indicator starts at the first tab on each side', (t) async {
    final ltr = await _indicatorCenterX(t, TextDirection.ltr, 0);
    final rtl = await _indicatorCenterX(t, TextDirection.rtl, 0);
    expect(ltr, lessThan(140)); // left half
    expect(rtl, greaterThan(140)); // right half
  });

  testWidgets('indicator follows the selected tab in RTL', (t) async {
    final x0 = await _indicatorCenterX(t, TextDirection.rtl, 0);
    final x2 = await _indicatorCenterX(t, TextDirection.rtl, 2);
    expect(x2, lessThan(x0));
  });
}
