import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_business_card_maker/app/modules/recent designs/widgets/pill_tab_selector.dart';

void main() {
  testWidgets('PillTabSelector renders in RTL', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            body: PillTabSelector(selectedIndex: 0, onChanged: (_) {}, labels: const ['ا', 'ب'])),
      ),
    ));
    expect(t.getCenter(find.text('ا')).dx, greaterThan(t.getCenter(find.text('ب')).dx));
  });
}
