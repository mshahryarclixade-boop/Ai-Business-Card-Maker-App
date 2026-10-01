import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../modules/custom_create/model/card_element_model.dart';

/// Converts the layout JSON Gemini returns for a finished card into a list
/// of [CardElement] JSON maps (the same shape CardEditorController saves
/// in `designData['elements']`), placed on the editor canvas.
class AiCardLayoutMapper {
  AiCardLayoutMapper._();

  static const double _fontSizeFactor = 0.9;

  /// The text box is nudged up by this fraction of the font size.
  static const double _textTopNudge = 0.12;

  /// The canvas draws each element inside a 4px padded container, so the
  /// stored position has to be 4px up/left of the visible glyphs.
  static const double _elementPad = 4;

  static const int _maxElements = 30;

  static Future<List<Map<String, dynamic>>> toElementsJson({
    required String layoutJson,
    required Uint8List imageBytes,
    required Size canvasSize,
  }) async {
    final decoded = jsonDecode(_stripFences(layoutJson));
    if (decoded is! Map) {
      throw const FormatException('Layout is not a JSON object');
    }

    final img = await _imageSize(imageBytes);

    final scale = math.max(
      canvasSize.width / img.width,
      canvasSize.height / img.height,
    );
    final offsetX = (img.width * scale - canvasSize.width) / 2;
    final offsetY = (img.height * scale - canvasSize.height) / 2;

    Offset toCanvas(double nx, double ny) => Offset(
      nx * img.width * scale - offsetX,
      ny * img.height * scale - offsetY,
    );

    Offset clampPos(Offset p) => Offset(
      p.dx.clamp(0.0, math.max(0.0, canvasSize.width - 10)).toDouble(),
      p.dy.clamp(0.0, math.max(0.0, canvasSize.height - 10)).toDouble(),
    );

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final result = <Map<String, dynamic>>[];

    // ------------------------------------------------------------- texts
    final texts = decoded['texts'];
    if (texts is List) {
      for (final raw in texts) {
        if (result.length >= _maxElements) break;
        if (raw is! Map) continue;

        final text = raw['text']?.toString().trim() ?? '';
        final x = _num(raw['x']);
        final y = _num(raw['y']);
        final h = _num(raw['h']);
        if (text.isEmpty || x == null || y == null || h == null) continue;

        final fontSize = (h * img.height * scale * _fontSizeFactor)
            .clamp(8.0, 64.0)
            .toDouble();

        final p = toCanvas(x, y);
        final pos = clampPos(Offset(
          p.dx - _elementPad,
          p.dy - _elementPad - fontSize * _textTopNudge,
        ));

        final weightIndex =
        (((_num(raw['weight']) ?? 400) / 100).round() - 1).clamp(0, 8);

        final font = raw['font']?.toString() ?? '';

        final el = CardElement(
          id: 'ai_${stamp}_${result.length}',
          type: CardElementType.text,
          position: pos,
          text: text,
          fontFamily: kSampleFontFamilies.contains(font)
              ? font
              : kSampleFontFamilies.first,
          fontSize: fontSize,
          color: _color(raw['color'], const Color(0xFF1E1E24)),
          fontWeight: FontWeight.values[weightIndex],
        );
        result.add(el.toJson());
      }
    }

    // ------------------------------------------------------------- icons
    final icons = decoded['icons'];
    if (icons is List) {
      for (final raw in icons) {
        if (result.length >= _maxElements) break;
        if (raw is! Map) continue;

        final icon = _iconFor(raw['name']?.toString());
        final x = _num(raw['x']);
        final y = _num(raw['y']);
        final h = _num(raw['h']);
        if (icon == null || x == null || y == null || h == null) continue;

        final size =
        (h * img.height * scale).clamp(10.0, 60.0).toDouble();

        final p = toCanvas(x, y);
        final pos = clampPos(Offset(
          p.dx - _elementPad,
          p.dy - _elementPad,
        ));

        final el = CardElement.sticker(
          id: 'ai_${stamp}_${result.length}',
          position: pos,
          iconData: icon,
          width: size,
          height: size,
          tintColor: _color(raw['color'], const Color(0xFF1E1E24)),
        );
        result.add(el.toJson());
      }
    }

    return result;
  }

  // ---------------------------------------------------------------- helpers

  static IconData? _iconFor(String? name) {
    switch (name?.toLowerCase().trim()) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'web':
        return Icons.language;
      case 'location':
        return Icons.location_on;
      case 'social':
        return Icons.link;
      default:
        return null;
    }
  }

  static double? _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static Color _color(dynamic v, Color fallback) {
    if (v is! String) return fallback;
    var s = v.trim().replaceAll('#', '');
    if (s.length == 3) {
      s = s.split('').map((c) => '$c$c').join();
    }
    if (s.length != 6) return fallback;
    final n = int.tryParse(s, radix: 16);
    if (n == null) return fallback;
    return Color(0xFF000000 | n);
  }

  static String _stripFences(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
      t = t.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return t.trim();
  }

  static Future<Size> _imageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } finally {
      codec.dispose();
    }
  }
}