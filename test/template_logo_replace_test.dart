import 'dart:convert';
import 'dart:io';

import 'package:ai_business_card_maker/app/modules/custom_create/model/card_element_model.dart';
import 'package:ai_business_card_maker/app/modules/template/model/template_live_data.dart';
import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';

List<CardElement> _side(String path, String side) {
  final d = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return [
    for (final e in (d[side]['elements'] as List))
      CardElement.fromJson(e as Map<String, dynamic>),
  ];
}

const _values = {
  'name': 'Jane Smith',
  'title': 'Manager',
  'company': 'Acme',
  'phone': '1',
  'email': 'a@b.c',
  'website': 'acme.com',
  'initial': 'A',
};

void main() {
  const travel10 = 'assets/template_json/travel/horizontal/travel_10.json';

  test('an uploaded logo replaces the template\'s own mark: one logo only', () {
    for (final side in ['front', 'back']) {
      final els = TemplateData.fillElements(_side(travel10, side), {
        ..._values,
        'logo': '/tmp/my_logo.png',
        'logo_aspect': '1',
      });
      expect(els.where((e) => e.field == 'initial'), isEmpty, reason: '$side monogram');
      final logos = els.where((e) => e.type == CardElementType.image).toList();
      expect(logos, hasLength(1), reason: side);
      expect(logos.single.imageFile!.path, '/tmp/my_logo.png');
      expect(logos.single.imageAsset, isNull);
    }
  });

  test('no uploaded logo: the template keeps its default mark, as before', () {
    for (final empty in [
      {..._values, 'logo': '', 'logo_aspect': '1'},
      {..._values}, // a caller that does not handle logos
    ]) {
      final els = TemplateData.fillElements(_side(travel10, 'front'), empty);
      expect(els.where((e) => e.field == 'initial'), hasLength(1));
    }
  });

  test('a template slot that carries a bundled default logo shows only the '
      'uploaded file; a stray bundled logo image is dropped', () {
    final slot = CardElement.fromJson({
      'id': 'logo_f', 'type': 'image', 'position': {'dx': 280, 'dy': 8}, 'rotation': 0,
      'text': '', 'fontFamily': 'SF Pro', 'fontSize': 18, 'color': 4279505963,
      'fontWeight': 3, 'width': 44, 'height': 44, 'imageMask': 'none', 'symbol': '',
      'tintColor': 4279505963, 'opacity': 1.0, 'field': 'logo', 'italic': false,
      'imageAsset': 'assets/images/template_logos/travel/horizontal/travel_01_logo.png',
    });
    final stray = CardElement.fromJson({
      ...slot.toJson(), 'id': 'old_logo', 'field': null,
      'position': {'dx': 10, 'dy': 10},
    });
    final out = TemplateData.fillElements([slot, stray], {'logo': '/tmp/x.png', 'logo_aspect': '2'});
    expect(out, hasLength(1));
    expect(out.single.imageFile!.path, '/tmp/x.png');
    expect(out.single.imageAsset, isNull);
    // Without an uploaded logo the default asset logo stays.
    final none = TemplateData.fillElements([slot, stray], {'logo': ''});
    expect(none.any((e) => e.id == 'old_logo'), isTrue);
  });

  group('every template (front and back)', () {
    final files = Directory('assets/template_json')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('/horizontal/') && f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    test('there are 20 templates', () => expect(files, hasLength(20)));

    for (final f in files) {
      final name = f.uri.pathSegments.last;
      test('$name: an uploaded logo leaves exactly ONE logo, in the place of the '
          'template\'s own mark; no logo keeps the default mark', () {
        final d = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final side in ['front', 'back']) {
          final els = _side(f.path, side);
          final marks = [
            for (final id in (d[side]['defaultLogoIds'] as List? ?? const [])) id as String,
          ];
          final withLogo = TemplateData.fillElements(
            els,
            {..._values, 'logo': '/tmp/up.png', 'logo_aspect': '1'},
            defaultLogoIds: marks,
          );
          // One image only, the uploaded one.
          final images = withLogo.where((e) => e.type == CardElementType.image).toList();
          expect(images, hasLength(1), reason: '$name $side');
          expect(images.single.imageFile!.path, '/tmp/up.png');
          // None of the template's own mark shapes is left.
          expect(withLogo.where((e) => marks.contains(e.id)), isEmpty, reason: '$name $side marks');
          expect(withLogo.where((e) => e.field == 'initial'), isEmpty);
          // With a mark, the logo sits on it.
          if (marks.isNotEmpty) {
            final area = els.where((e) => marks.contains(e.id)).map((e) => e.position & Size(e.width, e.height)).reduce((a, b) => a.expandToInclude(b));
            final logo = images.single;
            final center = logo.position + Offset(logo.width / 2, logo.height / 2);
            expect((center - area.center).distance, lessThan(1), reason: '$name $side');
          }
          // No uploaded logo: the template looks as before.
          final without = TemplateData.fillElements(els, {..._values, 'logo': ''}, defaultLogoIds: marks);
          expect(marks.every((id) => without.any((e) => e.id == id)), isTrue, reason: '$name $side default mark stays');
        }
      });
    }

    test('the marks are in the template files (a loaded template knows them)', () async {
      final base = (await TemplateData.loadPath('assets/template_json/spa_care/horizontal/spa_care_01.json'))!;
      expect(base.front.defaultLogoIds, isNotEmpty);
      final filled = base.filled({..._values, 'logo': '/tmp/up.png', 'logo_aspect': '1'});
      expect(filled.front.elements.where((e) => e.type == CardElementType.image), hasLength(1));
    });
  });
}
