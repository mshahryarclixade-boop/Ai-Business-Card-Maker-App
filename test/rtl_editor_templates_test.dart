import 'package:ai_business_card_maker/app/modules/custom_create/widgets/panel_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PanelHeader back arrow sits on the start side in RTL and LTR',
      (tester) async {
    for (final dir in [TextDirection.rtl, TextDirection.ltr]) {
      await tester.pumpWidget(MaterialApp(
        home: Directionality(
          textDirection: dir,
          child: Scaffold(body: PanelHeader(title: 'T', onBack: () {})),
        ),
      ));
      final x = tester.getCenter(find.byType(Icon)).dx;
      final w = tester.getSize(find.byType(Scaffold)).width;
      expect(dir == TextDirection.rtl ? x > w / 2 : x < w / 2, isTrue);
      expect(tester.takeException(), isNull);
    }
  });
}
