import 'package:ai_business_card_maker/app/core/utils/legal_links.dart';
import 'package:ai_business_card_maker/app/core/utils/share_origin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('without a context the anchor is a non-empty rect on screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final r = shareOrigin();
    expect(r.isEmpty, isFalse);
    expect(const Rect.fromLTWH(0, 0, 400, 800).contains(r.center), isTrue);
  });

  testWidgets('with a mounted widget the anchor is that widget\'s rect', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(key: key, width: 120, height: 40),
        ),
      ),
    );
    final r = shareOrigin(key.currentContext);
    expect(r.size, const Size(120, 40));
  });

  test('privacy policy and support email are per platform', () {
    expect(LegalLinks.privacyPolicyFor(ios: false),
        'https://clixade.com/moessa-app/privacy-policy');
    expect(LegalLinks.privacyPolicyFor(ios: true),
        'https://clixade.com/privacy-policy');
    expect(LegalLinks.supportEmailFor(ios: false), 'amoessa777@gmail.com');
    expect(LegalLinks.supportEmailFor(ios: true), 'contacts.clixade@gmail.com');
  });
}
