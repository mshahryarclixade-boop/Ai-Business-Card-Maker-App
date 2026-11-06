import 'dart:convert';

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../custom_create/model/card_element_model.dart';
import '../../../core/utils/app_fonts.dart';
import '../../profile_setup/model/user_profile_data.dart';
import '../../profile_setup/service/profile_logo_file.dart';
import '../../profile_setup/service/profile_store.dart';
import 'template_item.dart';

/// One side (front or back) of a template: a background + elements.
///
/// The background is a picture ([background], empty for none) or just a
/// colour ([backgroundColor]). A template built entirely from elements (see
/// travel_01) has no picture at all.
class TemplateSideData {
  final String background;
  final int? backgroundColor;
  final List<CardElement> elements;

  const TemplateSideData({
    this.background = '',
    this.backgroundColor,
    required this.elements,
  });

  /// A side as the editor saves it in `designData` (a background colour, a
  /// background picture as a file or an asset, and the elements).
  factory TemplateSideData.fromDesign(Map<String, dynamic> d) {
    final image = d['backgroundImagePath'] as String?;
    final asset = d['backgroundTemplate'] as String?;
    return TemplateSideData(
      background: image ?? asset ?? '',
      backgroundColor: (d['backgroundColor'] as num?)?.toInt(),
      elements: [
        for (final e in (d['elements'] as List? ?? const []))
          CardElement.fromJson(e as Map<String, dynamic>),
      ],
    );
  }

  /// There is a background picture (otherwise only the colour).
  bool get hasBackgroundImage => background.isNotEmpty;

  /// [background] is a file on disk (an AI frame), not a bundled asset.
  bool get isFileBackground => background.startsWith('/');
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
  static String jsonPathFor(TemplateItem t) => t.id == kAiCardTemplateId
      ? 'assets/template_json/first_card/first_card.json'
      : t.frontImagePath
      .replaceFirst('assets/images/templates/', 'assets/template_json/')
      .replaceFirst('_front.png', '.json');

  /// Returns null if the template has no JSON / empty backgrounds yet,
  /// so the caller can fall back to the old AI flow.
  static Future<TemplateData?> load(TemplateItem item) =>
      loadPath(jsonPathFor(item), fallbackId: item.id);

  /// Every landscape layout JSON bundled under assets/template_json/ —
  /// the layouts AI cards are built on (see AiFrameCardBuilder).
  static Future<List<String>> landscapeLayoutPaths() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where(
          (a) =>
              a.startsWith('assets/template_json/') &&
              a.contains('/horizontal/') &&
              a.endsWith('.json'),
        )
        .toList();
  }

  /// [load] for a layout JSON by its asset path.
  static Future<TemplateData?> loadPath(
    String path, {
    String fallbackId = '',
  }) async {
    if (_cache.containsKey(path)) return _cache[path];

    TemplateData? result;
    try {
      final raw = await rootBundle.loadString(path);
      final m = jsonDecode(raw) as Map<String, dynamic>;

      final front = _side(m['front'] as Map<String, dynamic>);
      final back = _side(m['back'] as Map<String, dynamic>);

      // Make sure the empty backgrounds really exist in the bundle.
      if (front.hasBackgroundImage) await rootBundle.load(front.background);
      if (back.hasBackgroundImage) await rootBundle.load(back.background);

      result = TemplateData._(
        id: (m['id'] as String?) ?? fallbackId,
        orientation: CardOrientation.values.byName(m['orientation'] as String),
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
      background: d['background'] as String? ?? '',
      backgroundColor: (d['backgroundColor'] as num?)?.toInt(),
      elements: els,
    );
  }

  /// JSON "field" key -> value from the user's profile.
  /// Fields the profile does not have (slogan, tagline, address1, address2,
  /// phone2) are left empty, so those texts are hidden.
  static Map<String, String> currentProfileValues() =>
      valuesOf(ProfileStore.to.profile.value);

  /// JSON "field" key -> value, for any profile (not only the active one).
  static Map<String, String> valuesOf(UserProfileData p) => {
    'name': p.fullName,
    'title': p.designation,
    'company': p.companyName,
    'phone': p.phone,
    'email': p.email,
    'website': p.website,
    'initial': initialOf(p.companyName.isNotEmpty ? p.companyName : p.fullName),
  };

  /// The first letter of [name], for a template's monogram ('' when none).
  static String initialOf(String name) {
    final t = name.trim();
    return t.isEmpty ? '' : String.fromCharCode(t.runes.first).toUpperCase();
  }

  /// [currentProfileValues] plus the company logo: `logo` is the file's path
  /// (empty when the profile has none) and `logo_aspect` its width / height.
  static Future<Map<String, String>> currentProfileValuesWithLogo() async {
    final values = currentProfileValues();
    final logo = await ProfileLogoFile.current();
    values['logo'] = logo?.file.path ?? '';
    values['logo_aspect'] = '${logo?.aspect ?? 1}';
    return values;
  }

  /// Space kept free at the right edge of a card for text (the canvas also
  /// insets everything by 4).
  static const double _textMargin = 12;

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
      if (key == 'logo' && e.type == CardElementType.image) {
        final logo = values['logo'];
        // The caller does not handle logos (first card, AI frames): untouched.
        if (logo == null) {
          out.add(e.copyWith());
          continue;
        }
        if (logo.isEmpty) continue; // no logo: no empty slot
        out.add(
          _logoInSlot(
            e,
            logo,
            double.tryParse(values['logo_aspect'] ?? '') ?? 1,
          ),
        );
        continue;
      }
      if (e.type != CardElementType.text || key == null) {
        // An icon that goes with a detail (phone, email, …) goes with it.
        final empty =
            key != null &&
            values.containsKey(key) &&
            values[key]!.trim().isEmpty;
        if (!empty) out.add(e.copyWith());
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

  /// [els] with every filled-in text kept on one line inside the card (see
  /// [_fitOneLine]). Separate from [fillElements] because it measures text,
  /// so the fonts must be loaded first (`AiFrameCardBuilder.loadFonts`).
  static List<CardElement> fitTexts(
    List<CardElement> els, {
    double canvasWidth = 340,
  }) => [
    for (final e in els)
      e.type == CardElementType.text && e.field != null
          ? _fitOneLine(e, canvasWidth)
          : e,
  ];

  /// [fitTexts] on both sides.
  TemplateData fitted() => TemplateData._(
    id: id,
    orientation: orientation,
    front: TemplateSideData(
      background: front.background,
      backgroundColor: front.backgroundColor,
      elements: fitTexts(
        front.elements,
        canvasWidth: orientation.canvasSize.width,
      ),
    ),
    back: TemplateSideData(
      background: back.background,
      backgroundColor: back.backgroundColor,
      elements: fitTexts(
        back.elements,
        canvasWidth: orientation.canvasSize.width,
      ),
    ),
  );

  /// The logo, as large as the slot allows but never stretched, centred in it.
  static CardElement _logoInSlot(CardElement slot, String path, double aspect) {
    final box = math.min(slot.width, slot.height);
    final w = aspect >= 1 ? box : box * aspect;
    final h = aspect >= 1 ? box / aspect : box;
    return slot.copyWith(
      imageFile: File(path),
      width: w,
      height: h,
      position:
          slot.position + Offset((slot.width - w) / 2, (slot.height - h) / 2),
    );
  }

  /// Keeps a one-line text inside the card: the font size is reduced only
  /// when the text would run past the right edge.
  static CardElement _fitOneLine(CardElement e, double canvasWidth) {
    final available = canvasWidth - 4 - e.position.dx - _textMargin;
    if (available <= 0) return e;
    final painter = TextPainter(
      text: TextSpan(
        text: e.text,
        style: AppFonts.textStyle(
          e.fontFamily,
          fontSize: e.fontSize,
          fontWeight: e.fontWeight,
          fontStyle: e.italic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    // A little headroom: the font may still be loading when this measures.
    final needed = painter.width * 1.03;
    if (needed <= available) return e;
    return e.copyWith(fontSize: e.fontSize * available / needed);
  }

  /// A copy of this template with the user's info filled in.
  TemplateData filled(Map<String, String> values) => TemplateData._(
    id: id,
    orientation: orientation,
    front: TemplateSideData(
      background: front.background,
      backgroundColor: front.backgroundColor,
      elements: fillElements(front.elements, values),
    ),
    back: TemplateSideData(
      background: back.background,
      backgroundColor: back.backgroundColor,
      elements: fillElements(back.elements, values),
    ),
  );

  /// A copy with other sides — e.g. an AI frame as the background and
  /// adjusted elements.
  TemplateData withSides({
    required TemplateSideData front,
    required TemplateSideData back,
  }) => TemplateData._(
    id: id,
    orientation: orientation,
    front: front,
    back: back,
  );

  /// Same format as CardEditorController.buildDesignData(), so the saved card
  /// reopens in the editor with everything editable.
  Map<String, dynamic> toDesignData() {
    Map<String, dynamic> side(TemplateSideData s) => {
      'backgroundColor': s.backgroundColor ?? 0xFFFFFFFF,
      'backgroundImagePath': s.isFileBackground ? s.background : null,
      'backgroundTemplate': s.isFileBackground || !s.hasBackgroundImage
          ? null
          : s.background,
      'elements': s.elements.map((e) => e.toJson()).toList(),
    };

    return {
      'orientation': orientation.name,
      ...side(front),
      'back': side(back),
    };
  }
}
