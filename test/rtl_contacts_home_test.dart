import 'package:ai_business_card_maker/app/modules/contacts/model/contact_model.dart';
import 'package:ai_business_card_maker/app/modules/contacts/widgets/contact_card.dart';
import 'package:ai_business_card_maker/app/modules/contacts/widgets/photo_header.dart';
import 'package:ai_business_card_maker/app/modules/contacts/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _rtl(Widget child, {double width = 320}) => MaterialApp(
      locale: const Locale('ur'),
      builder: (c, w) =>
          Directionality(textDirection: TextDirection.rtl, child: w!),
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );

void main() {
  testWidgets('PillButtons with long labels do not overflow in a narrow row',
      (t) async {
    await t.pumpWidget(_rtl(Row(children: [
      Expanded(
          child: PillButton(
              icon: Icons.edit,
              label: 'دستی طور پر رابطہ شامل کریں بہت لمبا متن',
              onTap: () {})),
      Expanded(
          child: PillButton(
              icon: Icons.edit, label: 'کارڈ اسکین کریں', onTap: () {})),
    ])));
    expect(t.takeException(), isNull);
  });

  testWidgets('PhotoHeader back button sits on the right in RTL', (t) async {
    await t.pumpWidget(_rtl(
      PhotoHeader(
        contact: ContactModel(
          id: '1',
          firstName: 'A',
          lastName: 'B',
          companyName: 'C',
        ),
        onBack: () {},
        onEdit: () {},
      ),
      width: 400,
    ));
    final back = t.getCenter(find.byIcon(Icons.arrow_back));
    final edit = t.getCenter(find.byIcon(Icons.edit));
    expect(back.dx, greaterThan(edit.dx));
    expect(t.takeException(), isNull);
  });

  testWidgets('ContactCard renders in RTL', (t) async {
    await t.pumpWidget(_rtl(ContactCard(
      contact: ContactModel(id: '1', firstName: 'علی', companyName: 'کمپنی'),
      onTap: () {},
      onDelete: () {},
    )));
    expect(t.takeException(), isNull);
  });
}
