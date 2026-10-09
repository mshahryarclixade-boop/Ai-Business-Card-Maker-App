import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import '../../modules/custom_create/model/card_element_model.dart';
import 'ai_card_layout_mapper.dart';
import 'ai_card_prompt_builder.dart';
import 'card_area_eraser.dart';
import 'gemini_card_service.dart';

/// A card side that can be edited: a text-free background plus the texts,
/// icons and logo as editor elements.
class EditableCard {
  final Uint8List background;
  final List<Map<String, dynamic>> elements;

  const EditableCard({required this.background, required this.elements});
}

class EditableCardBuilder {
  EditableCardBuilder._();

  static Future<EditableCard?> build({
    required GeminiCardService gemini,
    required Uint8List card,
    required Size canvasSize,
    String label = 'card',
    List<String> knownTexts = const [],
    String? logoFilePath,
  }) async {
    try {
      final expected = knownTexts
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final eraseLogo = logoFilePath != null;

      final layoutPrompt = AiCardPromptBuilder.buildEditableLayoutPrompt(
        fonts: kSampleFontFamilies,
        expected: expected,
      );

      final (firstBackground, firstLayoutJson) = await (
      gemini.generateCard(
        prompt: AiCardPromptBuilder.buildEditableErasePrompt(
          knownTexts: expected,
          eraseLogo: eraseLogo,
        ),
        referenceBytes: card,
        referenceMime: 'image/png',
      ),
      gemini.generateLayoutJson(
        prompt: layoutPrompt,
        imageBytes: card,
        imageMime: 'image/png',
      ),
      ).wait;

      final layoutJson = await _fillMissing(
        gemini: gemini,
        card: card,
        layoutJson: firstLayoutJson,
        expected: expected,
        label: label,
      );

      debugPrint('EDITABLE [$label]: layout JSON = $layoutJson');

      final elements = await AiCardLayoutMapper.toElementsJson(
        layoutJson: layoutJson,
        imageBytes: card,
        canvasSize: canvasSize,
        logoFilePath: logoFilePath,
      );

      if (elements.isEmpty) {
        debugPrint('EDITABLE [$label]: no elements found, keeping flat image');
        return null;
      }

      // ---- what is still on the AI-erased background? Wipe it locally ----
      final printed = <String>[..._texts(layoutJson), ...expected];
      final iconNames = _iconNames(layoutJson);

      List<EraseBox> boxes;
      try {
        final checkJson = await gemini.generateLayoutJson(
          prompt: AiCardPromptBuilder.buildEditableLayoutPrompt(
            fonts: kSampleFontFamilies,
          ),
          imageBytes: firstBackground,
          imageMime: 'image/png',
        );
        boxes = _boxes(
          checkJson,
          printed: printed,
          iconNames: iconNames,
          logo: eraseLogo,
        );
      } catch (e) {
        debugPrint('EDITABLE [$label]: check failed ($e), wiping all areas');
        boxes = _boxes(layoutJson, logo: eraseLogo);
      }

      final background = await CardAreaEraser.erase(firstBackground, boxes);

      debugPrint(
        'EDITABLE [$label]: ready (elements=${elements.length}, '
            'locally wiped=${boxes.length})',
      );
      return EditableCard(background: background, elements: elements);
    } catch (e, st) {
      debugPrint('EDITABLE [$label]: failed, keeping flat image: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Boxes to wipe
  // ------------------------------------------------------------------

  /// [printed] / [iconNames] null = take every text / icon.
  static List<EraseBox> _boxes(
      String raw, {
        List<String>? printed,
        Set<String>? iconNames,
        required bool logo,
      }) {
    final m = _decode(raw);
    if (m == null) return const [];

    final out = <EraseBox>[];
    final printedNorm =
    printed?.map(_norm).where((s) => s.length >= 3).toList();

    final icons = m['icons'];
    if (icons is List) {
      for (final e in icons) {
        if (e is! Map) continue;
        final name = e['name']?.toString().toLowerCase().trim() ?? '';
        if (iconNames != null && !iconNames.contains(name)) continue;
        final x = AiCardLayoutMapper.unit(e['x']);
        final y = AiCardLayoutMapper.unit(e['y']);
        final h = AiCardLayoutMapper.unit(e['h']);
        if (x == null || y == null || h == null) continue;
        out.add(EraseBox(x, y, h));
      }
    }

    final texts = m['texts'];
    if (texts is List) {
      for (final e in texts) {
        if (e is! Map || e['text'] == null) continue;
        final text = e['text'].toString().trim();
        if (text.isEmpty) continue;
        if (printedNorm != null) {
          final n = _norm(text);
          if (n.length < 3) continue;
          if (!printedNorm.any((p) => p == n || p.contains(n) || n.contains(p))) {
            continue;
          }
        }
        final x = AiCardLayoutMapper.unit(e['x']);
        final y = AiCardLayoutMapper.unit(e['y']);
        final h = AiCardLayoutMapper.unit(e['h']);
        if (x == null || y == null || h == null) continue;
        out.add(EraseBox(x, y, h, widthFactor: text.length * 0.7));
      }
    }

    final l = m['logo'];
    if (logo && l is Map) {
      final x = AiCardLayoutMapper.unit(l['x']);
      final y = AiCardLayoutMapper.unit(l['y']);
      final w = AiCardLayoutMapper.unit(l['w']);
      final h = AiCardLayoutMapper.unit(l['h']);
      if (x != null && y != null && w != null && h != null) {
        out.add(EraseBox(x, y, h, w: w));
      }
    }

    return out;
  }

  static Set<String> _iconNames(String raw) {
    final m = _decode(raw);
    final icons = m?['icons'];
    if (icons is! List) return <String>{};
    return {
      for (final e in icons)
        if (e is Map && e['name'] != null)
          e['name'].toString().toLowerCase().trim(),
    };
  }

  // ------------------------------------------------------------------
  // Missing known texts: one extra (text-only) layout call
  // ------------------------------------------------------------------

  static Future<String> _fillMissing({
    required GeminiCardService gemini,
    required Uint8List card,
    required String layoutJson,
    required List<String> expected,
    required String label,
  }) async {
    if (expected.isEmpty) return layoutJson;

    final foundNorm =
    _texts(layoutJson).map(_norm).where((s) => s.length >= 3).toList();

    final missing = expected.where((e) {
      final n = _norm(e);
      if (n.length < 3) return false;
      return !foundNorm.any((f) => f.contains(n) || n.contains(f));
    }).toList();

    if (missing.isEmpty) return layoutJson;

    debugPrint('EDITABLE [$label]: layout missed $missing, asking again');

    try {
      final extra = await gemini.generateLayoutJson(
        prompt: AiCardPromptBuilder.buildEditableLayoutPrompt(
          fonts: kSampleFontFamilies,
          expected: missing,
        ),
        imageBytes: card,
        imageMime: 'image/png',
      );
      return _merge(layoutJson, extra);
    } catch (e) {
      debugPrint('EDITABLE [$label]: second layout call failed: $e');
      return layoutJson;
    }
  }

  /// Adds the texts of [b] that [a] does not already have. Everything else
  /// (icons, logo) is taken from [a].
  static String _merge(String a, String b) {
    try {
      final mapA = _decode(a);
      final mapB = _decode(b);
      if (mapA == null || mapB == null) return a;

      final textsA = (mapA['texts'] is List)
          ? List<dynamic>.from(mapA['texts'] as List)
          : <dynamic>[];
      final seen = <String>{
        for (final e in textsA)
          if (e is Map && e['text'] != null) _norm(e['text'].toString()),
      };

      final textsB = mapB['texts'];
      if (textsB is List) {
        for (final e in textsB) {
          if (e is! Map || e['text'] == null) continue;
          final n = _norm(e['text'].toString());
          if (n.isEmpty || seen.contains(n)) continue;
          seen.add(n);
          textsA.add(e);
        }
      }

      mapA['texts'] = textsA;
      return jsonEncode(mapA);
    } catch (_) {
      return a;
    }
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\p{P}\p{S}]', unicode: true), '');

  static Map<String, dynamic>? _decode(String raw) {
    var t = raw.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
      t = t.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final decoded = jsonDecode(t.trim());
    if (decoded is! Map) return null;
    return Map<String, dynamic>.from(decoded);
  }

  static List<String> _texts(String raw) {
    final decoded = _decode(raw);
    if (decoded == null) return const [];

    final list = decoded['texts'];
    if (list is! List) return const [];

    return [
      for (final e in list)
        if (e is Map && e['text'] != null) e['text'].toString().trim(),
    ].where((s) => s.isNotEmpty).toList();
  }
}