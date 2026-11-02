import 'package:ai_business_card_maker/app/modules/qr_code_generator/model/qr_style.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/widgets/styled_qr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const data = 'BEGIN:VCARD\nVERSION:3.0\nFN:Test Person\nEND:VCARD\n';

  Finder qrPaint() => find.descendant(
    of: find.byType(StyledQr),
    matching: find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter != null && w.size == Size.zero,
    ),
  );

  testWidgets('codes appear one per frame, then come straight from the cache', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final s in QrStyles.all)
              StyledQr(data: data, style: s, size: 80, padding: 4),
          ],
        ),
      ),
    );
    // First frame: nothing is drawn yet, the frame is not held up.
    expect(qrPaint(), findsNothing);
    await t.pump();
    expect(qrPaint(), findsNWidgets(1));
    for (var i = 0; i < QrStyles.all.length; i++) {
      await t.pump();
    }
    expect(qrPaint(), findsNWidgets(QrStyles.all.length));

    // Shown again (another screen): drawn at once, no waiting.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(
      MaterialApp(
        home: StyledQr(data: data, style: QrStyles.all.first, size: 80),
      ),
    );
    expect(qrPaint(), findsOneWidget);
  });

  testWidgets('changing the style swaps the drawing', (t) async {
    Widget app(QrStyle s) => MaterialApp(home: StyledQr(data: data, style: s, size: 80));
    await t.pumpWidget(app(QrStyles.all[0]));
    await t.pump();
    await t.pump();
    final before = t.widget<CustomPaint>(qrPaint()).painter;
    await t.pumpWidget(app(QrStyles.all[1]));
    await t.pump();
    await t.pump();
    expect(identical(t.widget<CustomPaint>(qrPaint()).painter, before), isFalse);
  });
}
