import 'dart:convert';
import 'dart:io';

import 'package:ai_business_card_maker/app/modules/custom_create/model/card_element_model.dart';
import 'package:ai_business_card_maker/app/modules/template/model/template_live_data.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

List<File> _layouts() => Directory('assets/template_json')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.json') && !f.path.contains('first_card'))
    .toList();

Map<String, dynamic> _side(Map<String, dynamic> d, String s) =>
    d[s] as Map<String, dynamic>;

// 'SF Pro' is a plain system font; the Google fonts would need the network.
List<CardElement> _els(Map<String, dynamic> side) => [
  for (final e in side['elements'] as List)
    CardElement.fromJson(
      e as Map<String, dynamic>,
    ).copyWith(fontFamily: 'SF Pro'),
];

const _long = {
  'name': 'WWWWWWWWWWWWWWWWWWWW',
  'title': 'WWWWWWWWWWWWWWWWWWWW',
  'company': 'WWWWWWWWWWWWWWWWWWWW',
  'phone': '+92 300 1234567890',
  'email': 'wwwwwwwwwwwwwwwwwwww',
  'website': 'wwwwwwwwwwwwwwwwwwww',
};

void main() {
  test('every template has a logo slot on both sides', () {
    final files = _layouts();
    expect(files.length, 20);
    for (final f in files) {
      final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final s in ['front', 'back']) {
        final slots = _els(
          _side(d, s),
        ).where((e) => e.field == 'logo').toList();
        expect(slots.length, 1, reason: '${f.path} $s');
      }
    }
  });

  test('the logo is filled, kept inside the card and not stretched', () {
    for (final f in _layouts()) {
      final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final s in ['front', 'back']) {
        final out = TemplateData.fillElements(_els(_side(d, s)), {
          ..._long,
          'logo': '/tmp/logo.png',
          'logo_aspect': '2.0',
        });
        final logo = out.singleWhere((e) => e.field == 'logo');
        expect(logo.imageFile?.path, '/tmp/logo.png');
        expect(logo.width / logo.height, closeTo(2.0, 0.001));
        expect(logo.position.dx, greaterThanOrEqualTo(0), reason: f.path);
        expect(logo.position.dy, greaterThanOrEqualTo(0), reason: f.path);
        expect(
          logo.position.dx + logo.width + 4,
          lessThanOrEqualTo(340),
          reason: f.path,
        );
        expect(
          logo.position.dy + logo.height + 4,
          lessThanOrEqualTo(214),
          reason: f.path,
        );
      }
    }
  });

  test('without a logo no empty slot is left', () {
    for (final f in _layouts()) {
      final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final out = TemplateData.fillElements(_els(_side(d, 'front')), {
        ..._long,
        'logo': '',
      });
      expect(out.where((e) => e.field == 'logo'), isEmpty);
    }
  });

  test('a caller that does not know logos keeps the slot (first card)', () {
    final d =
        jsonDecode(
              File(
                'assets/template_json/first_card/first_card.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final out = TemplateData.fillElements(_els(_side(d, 'front')), _long);
    expect(out.where((e) => e.field == 'logo').length, 1);
  });

  test('a 20 character name stays on one line inside the card', () {
    for (final f in _layouts()) {
      final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final s in ['front', 'back']) {
        final out = TemplateData.fitTexts(
          TemplateData.fillElements(_els(_side(d, s)), {..._long, 'logo': ''}),
        );
        for (final e in out.where((e) => e.type == CardElementType.text)) {
          final tp = TextPainter(
            text: TextSpan(
              text: e.text,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: e.fontSize,
                fontWeight: e.fontWeight,
              ),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          // Measured the way the fit measures it: one line, and its right
          // end is inside the card (12 px margin).
          expect(
            tp.width,
            lessThanOrEqualTo(340 - 4 - e.position.dx - 12 + 0.5),
            reason: '${f.path} $s ${e.field}',
          );
        }
      }
    }
  });

  test('a long text is shrunk only when it would pass the right edge', () {
    final el = CardElement(
      id: 't',
      type: CardElementType.text,
      position: const Offset(191, 88),
      text: 'x',
      fontSize: 15.7,
      fontFamily: 'SF Pro',
      field: 'name',
    );
    final longOut = TemplateData.fitTexts(
      TemplateData.fillElements([el], {'name': 'WWWWWWWWWWWWWWWWWWWW'}),
    ).single;
    expect(longOut.fontSize, lessThan(15.7)); // shrunk
    final shortOut = TemplateData.fitTexts(
      TemplateData.fillElements([el], {'name': 'Al'}),
    ).single;
    expect(shortOut.fontSize, 15.7); // untouched
  });
}
