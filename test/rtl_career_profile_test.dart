import 'package:ai_business_card_maker/app/modules/career_studio/widgets/career_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester t, TextDirection d) => t.pumpWidget(
  MaterialApp(
    builder: (c, w) => Directionality(textDirection: d, child: w!),
    home: const Scaffold(
      body: CareerAppBar(title: 'Title', trailing: Icon(Icons.star)),
    ),
  ),
);

void main() {
  testWidgets('CareerAppBar LTR: back left, trailing right, 20 padding', (t) async {
    await _pump(t, TextDirection.ltr);
    final w = t.view.physicalSize.width / t.view.devicePixelRatio;
    expect(t.getCenter(find.byType(IconButton)).dx, lessThan(w / 2));
    expect(t.getTopLeft(find.byType(IconButton)).dx, 0);
    expect(w - t.getTopRight(find.byIcon(Icons.star)).dx, 20);
  });

  testWidgets('CareerAppBar RTL: back right, trailing left, 20 padding', (t) async {
    await _pump(t, TextDirection.rtl);
    final w = t.view.physicalSize.width / t.view.devicePixelRatio;
    expect(t.getCenter(find.byType(IconButton)).dx, greaterThan(w / 2));
    expect(w - t.getTopRight(find.byType(IconButton)).dx, 0);
    expect(t.getTopLeft(find.byIcon(Icons.star)).dx, 20);
    expect(t.takeException(), isNull);
  });
}
