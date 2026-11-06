import 'dart:convert';
import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_controller.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_symbols_controller_ext.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/model/card_element_model.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/widgets/canvas.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/template/model/template_live_data.dart';
import 'package:ai_business_card_maker/app/modules/template/widget/template_live_preview.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;

const _sets = {
  'travel': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  'spa_care': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
};

String _key(String cat, int n) => '${cat}_${n.toString().padLeft(2, '0')}';

String _path(String cat, int n) =>
    'assets/template_json/$cat/horizontal/${_key(cat, n)}.json';

const _profile = {
  'name': 'Alex Morgan',
  'title': 'Travel Consultant',
  'company': 'SKYWAY',
  'phone': '+1 202 555 0147',
  'email': 'alex@example.com',
  'website': 'www.example.com',
  'logo': '',
  'initial': 'S',
};

/// The template with plain system fonts: the Google fonts it uses need the
/// network, which tests do not have.
TemplateSideData _plain(TemplateSideData s) => TemplateSideData(
  background: s.background,
  backgroundColor: s.backgroundColor,
  elements: [for (final e in s.elements) e.copyWith(fontFamily: 'SF Pro')],
);

void _load(CardEditorController c, Map<String, dynamic> data) => c.loadFromDesign(
  RecentDesign(id: 'x', path: '/x.png', savedAt: DateTime(2026), designData: data),
);

final _recents = RecentDesignsService();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Real async (the big template files load through an isolate, which a widget
  // test's fake clock cannot run): prepared once, here.
  final designs = <String, Map<String, dynamic>>{};
  final filledOf = <String, TemplateData>{};
  final baseOf = <String, TemplateData>{};

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('t1').path,
        );
    await GetStorage.init();
    await _recents.init();
    for (final cat in _sets.keys) {
      for (final n in _sets[cat]!) {
        final base = (await TemplateData.loadPath(_path(cat, n)))!;
        final k = _key(cat, n);
        baseOf[k] = base;
        final f = base.filled(_profile);
        final plain = f.withSides(front: _plain(f.front), back: _plain(f.back));
        filledOf[k] = plain;
        designs[k] = plain.toDesignData();
      }
    }
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    Get.put(ProfileStore());
  });

  List<CardElement> shapesOf(TemplateSideData s) =>
      [for (final e in s.elements) if (e.type == CardElementType.shape) e];

  for (final cat in _sets.keys) for (final n in _sets[cat]!) {
    final k = _key(cat, n);
    group(k, () {
      test('is built from separate elements, not a flattened picture', () {
        final d = jsonDecode(File(_path(cat, n)).readAsStringSync()) as Map<String, dynamic>;
        for (final side in ['front', 'back']) {
          final s = d[side] as Map<String, dynamic>;
          expect(s.containsKey('background'), isFalse, reason: '$side has no background picture');
          expect(s['backgroundColor'], isA<int>());
          final els = [for (final e in s['elements'] as List) CardElement.fromJson(e as Map<String, dynamic>)];
          final shapes = els.where((e) => e.type == CardElementType.shape).toList();
          // Template 10's back is just one accent line (the big letter is text).
          expect(shapes.length, greaterThanOrEqualTo(1), reason: '$side');
          expect(els.where((e) => e.type == CardElementType.image && e.field != 'logo'), isEmpty);
          expect({for (final e in els) e.id}.length, els.length, reason: 'unique ids');
          expect(els.where((e) => e.field == 'logo').length, 1, reason: 'logo slot');
          for (final e in shapes) {
            final again = CardElement.fromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>);
            expect(again.symbol, e.symbol);
            expect(again.tintColor, e.tintColor);
            expect(again.width, e.width);
            expect(again.height, e.height);
            expect(again.position, e.position);
          }
        }
      });

      test('every shape stays inside the card', () {
        final base = baseOf[k]!;
        for (final side in [base.front, base.back]) {
          for (final e in shapesOf(side)) {
            // The canvas draws elements 4 units in from their position.
            expect(e.position.dx + 4, greaterThanOrEqualTo(-0.6), reason: e.id);
            expect(e.position.dy + 4, greaterThanOrEqualTo(-0.6), reason: e.id);
            expect(e.position.dx + 4 + e.width, lessThanOrEqualTo(340.6), reason: e.id);
            expect(e.position.dy + 4 + e.height, lessThanOrEqualTo(214.6), reason: e.id);
          }
        }
      });

      test('profile data fills the texts; no logo leaves no empty slot', () {
        final f = filledOf[k]!;
        final front = {
          for (final e in f.front.elements.where((e) => e.type == CardElementType.text)) e.field: e.text,
        };
        expect(front['name'], 'Alex Morgan');
        expect(front['title'], 'Travel Consultant');
        expect(front['phone'], '+1 202 555 0147');
        expect(front['email'], 'alex@example.com');
        expect(f.front.elements.where((e) => e.field == 'logo'), isEmpty);
        expect(f.back.elements.where((e) => e.field == 'logo'), isEmpty);
        final back = {
          for (final e in f.back.elements.where((e) => e.type == CardElementType.text)) e.field: e.text,
        };
        expect(back['website'], 'www.example.com');
      });

      test('with a logo the slot is filled', () {
        final f = TemplateData.fillElements(
          baseOf[k]!.front.elements,
          {..._profile, 'logo': '/x/logo.png', 'logo_aspect': '1'},
        );
        expect(f.where((e) => e.field == 'logo').length, 1);
        expect(f.firstWhere((e) => e.field == 'logo').imageFile?.path, '/x/logo.png');
      });

      group('editing, saving, loading, exporting', () {
        late CardEditorController c;

        setUp(() {
          c = Get.put(CardEditorController());
          _load(c, designs[k]!);
        });

        test('move, resize, recolour, layer and edit text; undoable', () {
          final shapes = c.elements.where((e) => e.type == CardElementType.shape).toList();
          final first = shapes.first, last = shapes.last;
          c.selectElement(last.id);
          c.startDrag(last.id);
          c.updateDragPosition(last.id, const Offset(-60, 300)); // far outside the card
          c.endDrag();
          expect(c.elements.firstWhere((e) => e.id == last.id).position, const Offset(-60, 300));
          final w = c.elements.firstWhere((e) => e.id == last.id).width;
          c.resizeSelectedShapeBy(10, 4);
          expect(c.elements.firstWhere((e) => e.id == last.id).width, w + 10);
          c.setSelectedTint(const Color(0xFFFF0000));
          expect(c.elements.firstWhere((e) => e.id == last.id).tintColor, const Color(0xFFFF0000));
          c.selectElement(first.id);
          c.bringSelectedToFront();
          expect(c.elements.last.id, first.id);
          c.sendSelectedToBack();
          expect(c.elements.first.id, first.id);
          final name = c.elements.firstWhere((e) => e.field == 'name');
          c.selectElement(name.id);
          c.updateSelectedText(text: 'Sam Rivers', color: const Color(0xFF123456));
          expect(c.elements.firstWhere((e) => e.id == name.id).text, 'Sam Rivers');
          c.undo();
          expect(c.canUndo.value, isTrue);
        });

        test('saved JSON keeps every edit, and loads back identically', () {
          final shape = c.elements.firstWhere((e) => e.type == CardElementType.shape);
          c.selectElement(shape.id);
          c.updateDragPosition(shape.id, const Offset(10, 20));
          c.setSelectedTint(const Color(0xFF00AA00));
          c.bringSelectedToFront();
          final saved = jsonDecode(jsonEncode(c.buildDesignData())) as Map<String, dynamic>;

          Get.delete<CardEditorController>(force: true);
          final c2 = Get.put(CardEditorController());
          _load(c2, saved);
          final back = c2.elements.firstWhere((e) => e.id == shape.id);
          expect(back.position, const Offset(10, 20));
          expect(back.tintColor, const Color(0xFF00AA00));
          expect(back.symbol, shape.symbol);
          expect(c2.elements.last.id, shape.id);
          expect(c2.backgroundColor.value, Color(filledOf[k]!.front.backgroundColor!));
          c2.switchToSide(1);
          expect(c2.backgroundColor.value, Color(filledOf[k]!.back.backgroundColor!));
          expect(
            c2.elements.where((e) => e.type == CardElementType.shape).length,
            shapesOf(filledOf[k]!.back).length,
          );
        });

        testWidgets('export is the card only, on both sides', (t) async {
          Get.put(_recents);
          _recents.designs.clear();
          c.elements.add(CardElement.shape(id: 'away', position: const Offset(-120, -120), width: 60, height: 60, color: const Color(0xFF00FF00)));
          final key = GlobalKey();
          await t.pumpWidget(GetMaterialApp(home: Scaffold(body: Center(child: CardCanvas(controller: c, repaintKey: key)))));
          await t.pump();
          var done = false;
          final saving = c.saveToRecentDesigns(key).whenComplete(() => done = true);
          for (var i = 0; i < 200 && !done; i++) {
            await t.pump(const Duration(milliseconds: 50));
            await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          }
          await saving;
          expect(done, isTrue);
          // Saving the same card again updates it: never a second copy.
          var again = false;
          final saving2 = c.saveToRecentDesigns(key).whenComplete(() => again = true);
          for (var i = 0; i < 200 && !again; i++) {
            await t.pump(const Duration(milliseconds: 50));
            await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          }
          await saving2;
          expect(Get.find<RecentDesignsService>().designs.length, 1);
          final saved = Get.find<RecentDesignsService>().designs.first;
          final front = img.decodePng(await t.runAsync(() => saved.file.readAsBytes()) as Uint8List)!;
          final back = img.decodePng(await t.runAsync(() => saved.backFile!.readAsBytes()) as Uint8List)!;
          for (final im in [front, back]) {
            expect(im.width, 340 * 3);
            expect(im.height, 214 * 3);
            var green = 0;
            for (final p in im) {
              if (p.g == 255 && p.r == 0 && p.b == 0) green++;
            }
            expect(green, 0, reason: 'nothing outside the card is exported');
          }
          // The corner pixel is the side's own background colour (each side
          // differs): the saved front and back are not the same picture.
          Color px(img.Image im) {
            final p = im.getPixel(2, 2);
            return Color.fromARGB(255, p.r.toInt(), p.g.toInt(), p.b.toInt());
          }
          expect(px(front), isNot(equals(const Color(0xFF00FF00))));
          expect(px(back), isNot(equals(const Color(0xFF00FF00))));
        });
      });
    });
  }

  group('Template 10 monogram', () {
    test('the big letter is the first letter of the company, on both sides', () {
      final f = filledOf['travel_10']!;
      for (final side in [f.front, f.back]) {
        final m = side.elements.firstWhere((e) => e.id.endsWith('_monogram'));
        expect(m.text, 'S'); // _profile['initial']
        expect(m.field, 'initial');
      }
    });

    test('initialOf takes the company, falls back to nothing when empty', () {
      expect(TemplateData.initialOf('  atlas travel'), 'A');
      expect(TemplateData.initialOf(''), '');
    });
  });

  group('Template 1', () {
    test('the blue strip ends exactly at the card edge', () {
      final base = baseOf['travel_01']!;
      for (final side in [base.front, base.back]) {
        final panel = side.elements.firstWhere((e) => e.id.endsWith('_panel'));
        expect(panel.position.dx + 4 + panel.width, closeTo(340, 0.01));
        expect(panel.position.dy + 4, closeTo(0, 0.01));
        expect(panel.position.dy + 4 + panel.height, closeTo(214, 0.01));
      }
    });
  });

  group('the Background panel colours', () {
    late CardEditorController c;
    setUp(() {
      c = Get.put(CardEditorController());
      _load(c, designs['travel_01']!);
    });

    test('recolour the selected shape (strip, icon...) and leave the card background', () {
      final bg = c.backgroundColor.value;
      final strip = c.elements.firstWhere((e) => e.id == 'travel_01_f_panel');
      c.selectElement(strip.id);
      expect(c.toolColorTarget, ColorPickerTarget.element);
      c.setToolColor(const Color(0xFFAA00AA));
      expect(c.elements.firstWhere((e) => e.id == strip.id).tintColor, const Color(0xFFAA00AA));
      expect(c.backgroundColor.value, bg);
      expect(c.toolColor, const Color(0xFFAA00AA));
    });

    test('recolour the selected text', () {
      final name = c.elements.firstWhere((e) => e.field == 'name');
      c.selectElement(name.id);
      expect(c.toolColorTarget, ColorPickerTarget.text);
      c.setToolColor(const Color(0xFF00AAAA));
      expect(c.elements.firstWhere((e) => e.id == name.id).color, const Color(0xFF00AAAA));
    });

    test('with nothing selected the card background changes', () {
      c.selectElement(null);
      expect(c.toolColorTarget, ColorPickerTarget.background);
      final shapesBefore = [for (final e in c.elements) e.tintColor];
      c.setToolColor(const Color(0xFF112233));
      expect(c.backgroundColor.value, const Color(0xFF112233));
      expect([for (final e in c.elements) e.tintColor], shapesBefore);
    });

    test('a colour change is undoable', () {
      final strip = c.elements.firstWhere((e) => e.id == 'travel_01_f_panel');
      final before = strip.tintColor;
      c.selectElement(strip.id);
      c.setToolColor(const Color(0xFFAA00AA));
      c.undo();
      expect(c.elements.firstWhere((e) => e.id == strip.id).tintColor, before);
    });
  });

  group('what shows where a shape was (no leftover patches)', () {
    /// The side drawn with its shapes only, 2 pixels per card unit.
    Future<img.Image> render(WidgetTester t, TemplateSideData side) async {
      final key = GlobalKey();
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: TemplateCardCanvas(
              side: TemplateSideData(
                backgroundColor: side.backgroundColor,
                elements: [for (final e in side.elements) if (e.type == CardElementType.shape) e],
              ),
              orientation: CardOrientation.landscape,
              repaintKey: key,
            ),
          ),
        ),
      );
      await t.pump();
      final bytes = await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      return img.decodePng(bytes!)!;
    }

    int rgb(img.Pixel p) => (p.r.toInt() << 16) | (p.g.toInt() << 8) | p.b.toInt();

    testWidgets('the card background colour shows wherever the original showed its backdrop (all 20 templates)', (t) async {
      const magenta = 0xFFFF00FF;
      for (final cat in _sets.keys) {
        for (final n in _sets[cat]!) {
          final k = _key(cat, n);
          for (final side in ['front', 'back']) {
            final base = side == 'front' ? baseOf[k]!.front : baseOf[k]!.back;
            final original = img.decodePng(
              File('assets/images/empty_templates/$cat/horizontal/${k}_$side.png').readAsBytesSync(),
            )!;
            // How much of the original is the backdrop (cropped like the card).
            final bg = base.backgroundColor!;
            var backdrop = 0, total = 0;
            for (var y = 17; y < 583; y += 3) {
              for (var x = 0; x < 900; x += 3) {
                final p = original.getPixel(x, y);
                final d = [
                  (p.r.toInt() - ((bg >> 16) & 255)).abs(),
                  (p.g.toInt() - ((bg >> 8) & 255)).abs(),
                  (p.b.toInt() - (bg & 255)).abs(),
                ].reduce((a, b) => a > b ? a : b);
                if (d <= 10) backdrop++;
                total++;
              }
            }
            final expected = backdrop / total;

            final recoloured = TemplateSideData(backgroundColor: magenta, elements: base.elements);
            final out = await render(t, recoloured);
            var shown = 0;
            for (final p in out) {
              // Mostly magenta: a thin line only dims the pixels it touches.
              if (p.r > 195 && p.g < 60 && p.b > 195) shown++;
            }
            final actual = shown / (out.width * out.height);
            expect(
              (actual - expected).abs(),
              // A leftover patch is tens of percent; many thin anti-aliased lines can
              // account for a few percent.
              lessThan(0.08),
              reason: '$k $side: the backdrop is ${(expected * 100).round()}% of the original '
                  'but only ${(actual * 100).round()}% follows the card colour',
            );
          }
        }
      }
    });

    testWidgets('moving the sun off the arch reveals the arch, not the card background', (t) async {
      final back = baseOf['travel_05']!.back;
      final sun = back.elements.firstWhere((e) => e.type == CardElementType.shape && e.tintColor.toARGB32() == 0xFFF7D7A0);
      final centre = sun.position + Offset(sun.width / 2 + 4, sun.height / 2 + 4);
      final moved = TemplateSideData(
        backgroundColor: back.backgroundColor,
        elements: [
          for (final e in back.elements)
            e.id == sun.id ? e.copyWith(position: const Offset(-200, -200)) : e,
        ],
      );
      final out = await render(t, moved);
      expect(rgb(out.getPixel((centre.dx * 2).round(), (centre.dy * 2).round())), 0x97D2D9);
    });

    testWidgets('moving a white icon off a coloured strip reveals the strip', (t) async {
      final front = baseOf['travel_08']!.front;
      final bg = front.backgroundColor!;
      final strip = front.elements.firstWhere((e) => e.type == CardElementType.shape && e.tintColor.toARGB32() == 0xFF087788);
      final icon = front.elements.firstWhere(
        (e) => e.type == CardElementType.shape &&
            e.tintColor.toARGB32() == bg &&
            e.position.dx >= strip.position.dx &&
            e.position.dx + e.width <= strip.position.dx + strip.width,
      );
      final centre = icon.position + Offset(icon.width / 2 + 4, icon.height / 2 + 4);
      final moved = TemplateSideData(
        backgroundColor: bg,
        elements: [
          for (final e in front.elements)
            e.id == icon.id ? e.copyWith(position: const Offset(-200, -200)) : e,
        ],
      );
      final out = await render(t, moved);
      expect(rgb(out.getPixel((centre.dx * 2).round(), (centre.dy * 2).round())), 0x087788);
    });
  });
}
