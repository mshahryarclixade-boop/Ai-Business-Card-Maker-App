import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart'
    show AssetImage, Color, FileImage, ImageProvider;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../modules/custom_create/model/card_element_model.dart';
import '../../modules/template/model/template_live_data.dart';
import '../../modules/template/widget/template_live_preview.dart';
import '../utils/app_fonts.dart';
import '../utils/widget_image_renderer.dart';
import 'ai_card_prompt_builder.dart';
import 'gemini_card_service.dart';
import 'recent_designs_service.dart';

/// Makes an AI card the cheap way: Gemini paints only the two text-free
/// FRAMES (front and back backgrounds), and the user's details are placed
/// on them from one of the bundled layouts (assets/template_json) — the same
/// layouts and profile filling the templates use. Two image calls per card,
/// no text on the AI's side to get wrong, and every card is editable from
/// the start.
abstract final class AiFrameCardBuilder {
  /// Creates, saves (My Cards) and returns the card.
  ///
  /// Each frame is a restyle of the layout's own empty background, whose
  /// plain areas are where the details go. [style] (a sample card or an
  /// image the user uploaded) and [userPrompt] only set the look; without a
  /// [style] the frame is a fresh variation of the layout's background.
  static Future<RecentDesign> create({
    Uint8List? style,
    String styleMime = 'image/png',
    ReferenceKind kind = ReferenceKind.template,
    required CardDetails details,
    String userPrompt = '',
    Uint8List? logo,
    String title = '',
  }) async {
    final layout = await _pickLayout();
    final filled = layout.filled({
      'name': details.name,
      'title': details.jobTitle,
      'company': details.company,
      'phone': details.phone,
      'email': details.email,
      'website': details.website,
    });
    final size = layout.orientation.canvasSize;

    final dir = await getApplicationDocumentsDirectory();
    final id = DateTime.now().microsecondsSinceEpoch;

    // The logo goes into a free corner of the front.
    var frontElements = filled.front.elements;
    if (logo != null && logo.isNotEmpty) {
      final logoFile = File('${dir.path}/ai_logo_$id.png');
      await logoFile.writeAsBytes(logo, flush: true);
      frontElements = [
        ...frontElements,
        _logoElement(logoFile, frontElements, size),
      ];
    }
    final backElements = filled.back.elements;

    // ---- the two frames (the only Gemini calls) ----
    final gemini = GeminiCardService();
    Future<Uint8List> frame(CardSide side, String emptyBackground) async {
      final composition = (await rootBundle.load(emptyBackground)).buffer
          .asUint8List();
      return gemini.generateCard(
        prompt: AiCardPromptBuilder.buildFrame(
          kind: kind,
          side: side,
          hasStyleImage: style != null,
          userPrompt: userPrompt,
        ),
        referenceBytes: composition,
        referenceMime: 'image/png',
        // The function's second image slot (logo) carries the style here.
        logoBytes: style,
        logoMime: styleMime,
      );
    }

    final frames = await Future.wait([
      frame(CardSide.front, layout.front.background),
      frame(CardSide.back, layout.back.background),
    ]);

    final frontFrame = File('${dir.path}/ai_frame_front_$id.png');
    final backFrame = File('${dir.path}/ai_frame_back_$id.png');
    await frontFrame.writeAsBytes(frames[0], flush: true);
    await backFrame.writeAsBytes(frames[1], flush: true);

    // ---- readable text on whatever the frame turned out to be ----
    final card = filled.withSides(
      front: TemplateSideData(
        background: frontFrame.path,
        elements: await _readable(frames[0], frontElements, size),
      ),
      back: TemplateSideData(
        background: backFrame.path,
        elements: await _readable(frames[1], backElements, size),
      ),
    );

    return saveCard(card, title: title);
  }

  /// Draws [card]'s thumbnails (with the same widget as template cards) and
  /// saves it to My Cards as an editable AI card.
  static Future<RecentDesign> saveCard(
    TemplateData card, {
    String title = '',
  }) async {
    await loadFonts([...card.front.elements, ...card.back.elements]);
    Future<Uint8List> thumb(TemplateSideData side) => WidgetImageRenderer.render(
      TemplateCardCanvas(side: side, orientation: card.orientation),
      size: card.orientation.canvasSize,
      images: <ImageProvider>[
        side.isFileBackground
            ? FileImage(File(side.background))
            : AssetImage(side.background),
        for (final e in side.elements)
          if (e.imageFile != null) FileImage(e.imageFile!),
      ],
    );
    final thumbs = await Future.wait([thumb(card.front), thumb(card.back)]);

    final service = Get.find<RecentDesignsService>();
    await service.save(
      thumbs[0],
      backThumbnailBytes: thumbs[1],
      designData: card.toDesignData(),
      title: title,
      isAiGenerated: true,
    );
    return service.designs.first;
  }

  // ------------------------------------------------------------------
  // Layout
  // ------------------------------------------------------------------

  static final _random = Random();

  /// A random landscape layout (any that fails to load is skipped).
  static Future<TemplateData> _pickLayout() async {
    final paths = await TemplateData.landscapeLayoutPaths()
      ..shuffle(_random);
    for (final path in paths) {
      final layout = await TemplateData.loadPath(path);
      if (layout != null) return layout;
    }
    throw const GeminiException('No card layout available.');
  }

  // ------------------------------------------------------------------
  // Areas
  // ------------------------------------------------------------------

  /// Same inset TemplateCardCanvas draws elements with.
  static const double _pad = 4;

  /// Roughly where an element sits on the canvas (text width estimated
  /// from its length — close enough to keep the frame calm there).
  static Rect _boxOf(CardElement e) {
    final left = e.position.dx + _pad;
    final top = e.position.dy + _pad;
    if (e.type == CardElementType.text) {
      return Rect.fromLTWH(
        left,
        top,
        e.text.length * e.fontSize * 0.6,
        e.fontSize * 1.35,
      );
    }
    return Rect.fromLTWH(left, top, e.width, e.height);
  }

  /// The user's logo, 44×44, in the first corner that no text overlaps.
  static CardElement _logoElement(
    File file,
    List<CardElement> others,
    Size size,
  ) {
    const side = 44.0, inset = 12.0;
    final taken = others.map(_boxOf).toList();
    final corners = [
      Offset(size.width - inset - side, inset), // top right
      const Offset(inset, inset), // top left
      Offset(size.width - inset - side, size.height - inset - side),
      Offset(inset, size.height - inset - side),
    ];
    final spot = corners.firstWhere(
      (c) => !taken.any(
        (t) => t.overlaps(Rect.fromLTWH(c.dx, c.dy, side, side).inflate(4)),
      ),
      orElse: () => corners.first,
    );
    return CardElement.image(
      id: 'ai_logo',
      position: spot - const Offset(_pad, _pad),
      file: file,
      width: side,
      height: side,
    )..field = 'logo';
  }

  // ------------------------------------------------------------------
  // Contrast
  // ------------------------------------------------------------------

  /// [els] with any text that would be hard to read on [frame] switched to
  /// near-black or white, whichever stands out more there.
  static Future<List<CardElement>> _readable(
    Uint8List frame,
    List<CardElement> els,
    Size size,
  ) async {
    final boxes = <List<double>>[
      for (final e in els)
        if (e.type == CardElementType.text)
          () {
            final r = _boxOf(e);
            return [
              r.left / size.width,
              r.top / size.height,
              r.right / size.width,
              r.bottom / size.height,
            ];
          }(),
    ];
    final List<double> backgrounds;
    try {
      backgrounds = await compute(_luminances, (frame, boxes));
    } catch (e) {
      debugPrint('AI FRAME: contrast check skipped ($e)');
      return els;
    }
    if (backgrounds.length != boxes.length) return els;

    var i = 0;
    return [
      for (final e in els)
        if (e.type != CardElementType.text)
          e
        else
          () {
            final bg = backgrounds[i++];
            if (_contrast(_luminance(e.color), bg) >= 3) return e;
            const dark = Color(0xFF1F1F24), light = Color(0xFFFFFFFF);
            final better =
                _contrast(_luminance(dark), bg) >=
                    _contrast(_luminance(light), bg)
                ? dark
                : light;
            return e.copyWith(color: better);
          }(),
    ];
  }

  static double _luminance(Color c) => c.computeLuminance();

  static double _contrast(double a, double b) =>
      (max(a, b) + 0.05) / (min(a, b) + 0.05);

  /// Loads the fonts [els] use, so they draw (and measure) correctly.
  static Future<void> loadFonts(List<CardElement> els) async {
    for (final e in els) {
      if (e.type == CardElementType.text) {
        AppFonts.textStyle(e.fontFamily, fontWeight: e.fontWeight);
      }
    }
    try {
      await GoogleFonts.pendingFonts();
    } catch (e) {
      debugPrint('AI FRAME: fonts not loaded ($e)');
    }
  }
}

/// Average relative luminance (0–1) of the frame under each box — run in
/// an isolate, decoding a full-size image is slow.
List<double> _luminances((Uint8List, List<List<double>>) args) {
  final (bytes, boxes) = args;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return const [];
  final w = decoded.width, h = decoded.height;
  double channel(num v) {
    final c = v / 255;
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return [
    for (final b in boxes)
      () {
        final x0 = (b[0].clamp(0.0, 1.0) * (w - 1)).round();
        final y0 = (b[1].clamp(0.0, 1.0) * (h - 1)).round();
        final x1 = (b[2].clamp(0.0, 1.0) * (w - 1)).round();
        final y1 = (b[3].clamp(0.0, 1.0) * (h - 1)).round();
        var sum = 0.0, n = 0;
        final stepX = max(1, (x1 - x0) ~/ 24), stepY = max(1, (y1 - y0) ~/ 8);
        for (var y = y0; y <= y1; y += stepY) {
          for (var x = x0; x <= x1; x += stepX) {
            final p = decoded.getPixel(x, y);
            sum += 0.2126 * channel(p.r) +
                0.7152 * channel(p.g) +
                0.0722 * channel(p.b);
            n++;
          }
        }
        return n == 0 ? 1.0 : sum / n;
      }(),
  ];
}
