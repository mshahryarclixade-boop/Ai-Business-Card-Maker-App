import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../custom_create/model/card_element_model.dart';
import '../../profile_setup/service/profile_store.dart';
import 'template_item.dart';

/// One side (front or back) of a template: empty background + elements.
class TemplateSideData {
  final String background;
  final List<CardElement> elements;

  const TemplateSideData({required this.background, required this.elements});
}

/// A template read from assets/template_json/... (empty background PNGs +
/// element positions). Used for the instant, AI-free preview on Home and
/// for saving the applied card in the editor's own designData format.
class TemplateData {
  final String id;
  final CardOrientation orientation;
  final TemplateSideData front;
  final TemplateSideData back;

  const TemplateData._({
    required this.id,
    required this.orientation,
    required this.front,
    required this.back,
  });

  static final Map<String, TemplateData?> _cache = {};

  /// Same rule the editor uses to find a template's JSON.
  static String jsonPathFor(TemplateItem t) => t.frontImagePath
      .replaceFirst('assets/images/templates/', 'assets/template_json/')
      .replaceFirst('_front.png', '.json');

  /// Returns null if the template has no JSON / empty backgrounds yet,
  /// so the caller can fall back to the old AI flow.
  static Future<TemplateData?> load(TemplateItem item) async {
    final path = jsonPathFor(item);
    if (_cache.containsKey(path)) return _cache[path];

    TemplateData? result;
    try {
      final raw = await rootBundle.loadString(path);
      final m = jsonDecode(raw) as Map<String, dynamic>;

      final front = _side(m['front'] as Map<String, dynamic>);
      final back = _side(m['back'] as Map<String, dynamic>);

      // Make sure the empty backgrounds really exist in the bundle.
      await rootBundle.load(front.background);
      await rootBundle.load(back.background);

      result = TemplateData._(
        id: (m['id'] as String?) ?? item.id,
        orientation:
        CardOrientation.values.byName(m['orientation'] as String),
        front: front,
        back: back,
      );
    } catch (e) {
      debugPrint('TemplateData.load($path) -> not available: $e');
      result = null;
    }

    _cache[path] = result;
    return result;
  }

  static TemplateSideData _side(Map<String, dynamic> d) {
    final els = (d['elements'] as List<dynamic>? ?? const [])
        .map((e) => CardElement.fromJson(e as Map<String, dynamic>))
        .toList();
    return TemplateSideData(
      background: d['background'] as String,
      elements: els,
    );
  }

  /// JSON "field" key -> value from the user's profile.
  /// Fields the profile does not have (slogan, tagline, address1, address2,
  /// phone2) are left empty, so those texts are hidden.
  static Map<String, String> currentProfileValues() {
    final p = ProfileStore.to.profile.value;
    return {
      'name': p.fullName,
      'title': p.designation,
      'company': p.companyName,
      'phone': p.phone,
      'email': p.email,
      'website': p.website,
    };
  }

  /// Copies [els], replacing every text that has a "field" with the user's
  /// value. Empty values are removed, so no sample text is left on the card.
  /// If the sample text was UPPERCASE (e.g. "MICHAEL JOHNS"), the user's
  /// value is uppercased too, to match the design.
  static List<CardElement> fillElements(
      List<CardElement> els,
      Map<String, String> values,
      ) {
    final out = <CardElement>[];
    for (final e in els) {
      final key = e.field;
      if (e.type != CardElementType.text || key == null) {
        out.add(e.copyWith());
        continue;
      }

      final v = (values[key] ?? '').trim();
      if (v.isEmpty) continue;

      final sample = e.text;
      final sampleIsUpper =
          sample != sample.toLowerCase() && sample == sample.toUpperCase();

      out.add(e.copyWith(text: sampleIsUpper ? v.toUpperCase() : v));
    }
    return out;
  }

  /// A copy of this template with the user's info filled in.
  TemplateData filled(Map<String, String> values) => TemplateData._(
    id: id,
    orientation: orientation,
    front: TemplateSideData(
      background: front.background,
      elements: fillElements(front.elements, values),
    ),
    back: TemplateSideData(
      background: back.background,
      elements: fillElements(back.elements, values),
    ),
  );

  /// Same format as CardEditorController.buildDesignData(), so the saved card
  /// reopens in the editor with everything editable.
  Map<String, dynamic> toDesignData() {
    Map<String, dynamic> side(TemplateSideData s) => {
      'backgroundColor': 0xFFFFFFFF,
      'backgroundImagePath': null,
      'backgroundTemplate': s.background,
      'elements': s.elements.map((e) => e.toJson()).toList(),
    };

    return {
      'orientation': orientation.name,
      ...side(front),
      'back': side(back),
    };
  }
}