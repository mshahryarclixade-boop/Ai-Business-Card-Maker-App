import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/ai_card_layout_mapper.dart';
import '../../../core/services/ai_card_prompt_builder.dart';
import '../../../core/services/editable_card_builder.dart';
import '../../../core/services/gemini_card_service.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../custom_create/model/card_element_model.dart';
import '../model/user_profile_data.dart';

class _Side {
  const _Side(this.card, {this.background, this.elements});

  final Uint8List card;
  final Uint8List? background;
  final List<Map<String, dynamic>>? elements;
}

/// Creates a card (front + back) from the details the user entered,

class FirstCardGenerator {
  /// The starting design for the first card.
  static const String templateAsset = 'assets/images/first_card_template.png';
  static const Size canvasSize = Size(350, 200);

  final GeminiCardService _gemini = GeminiCardService();

  Future<List<Uint8List>> generate(
      UserProfileData data, {
        String? templateAssetPath,
        String title = 'My First Card',
      }) async {
    final template = (await rootBundle
        .load(templateAssetPath ?? FirstCardGenerator.templateAsset))
        .buffer
        .asUint8List();
    final templateMime = _mimeOf(template);
    final details = CardDetails.fromUserProfile(data);
    final logo = data.hasLogo ? data.logoBytes : null;
    final logoMime = logo == null ? 'image/png' : _mimeOf(logo);

    final docs = await getApplicationDocumentsDirectory();
    String? logoPath;
    if (logo != null) {
      final f = File(
          '${docs.path}/ai_logo_${DateTime.now().microsecondsSinceEpoch}.png');
      await f.writeAsBytes(logo, flush: true);
      logoPath = f.path;
    }

    final sides = await Future.wait([
      _buildSide(CardSide.front, template, templateMime, details, logo,
          logoMime, logoPath),
      _buildSide(CardSide.back, template, templateMime, details, logo,
          logoMime, logoPath),
    ]);
    final front = sides[0];
    final back = sides[1];

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;

    Future<String> tmp(String name, Uint8List bytes) async {
      final file = File('${dir.path}/first_card_${stamp}_$name.png');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }

    Future<String?> tmpIfEditable(String name, _Side s) async =>
        (s.background != null && s.elements != null)
            ? tmp(name, s.background!)
            : null;

    await Get.find<RecentDesignsService>().saveAiCard(
      frontTempPath: await tmp('front', front.card),
      backTempPath: await tmp('back', back.card),
      frontBackgroundTempPath: await tmpIfEditable('front_bg', front),
      backBackgroundTempPath: await tmpIfEditable('back_bg', back),
      frontElements: front.elements,
      backElements: back.elements,
      title: title,
    );

    return [front.card, back.card];
  }

  Future<_Side> _buildSide(
      CardSide side,
      Uint8List template,
      String templateMime,
      CardDetails details,
      Uint8List? logo,
      String logoMime,
      String? logoPath,
      ) async {
    final prompt = AiCardPromptBuilder.build(
      kind: ReferenceKind.template,
      side: side,
      details: details,
      hasLogo: logo != null,
      removeSampleBranding: true,
    );

    // A failure here is real: it goes up to the "Try Again" screen.
    final Uint8List card;
    try {
      card = await _gemini.generateCard(
        prompt: prompt,
        referenceBytes: template,
        referenceMime: templateMime,
        logoBytes: logo,
        logoMime: logoMime,
      );
    } catch (e, st) {
      debugPrint('Card image failed (${side.name}): $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }

    // The editable version is a bonus. If it fails, the flat image is kept.
    final editable = await EditableCardBuilder.build(
      gemini: _gemini,
      card: card,
      canvasSize: CardOrientation.landscape.canvasSize,
      label: side.name,
      knownTexts: side == CardSide.front
          ? [
        details.name,
        details.jobTitle,
        details.company,
        details.phone,
        details.email,
        details.website,
      ]
          : [details.company, details.website],
      logoFilePath: logoPath,
    );
    if (editable == null) return _Side(card);

    return _Side(
      card,
      background: editable.background,
      elements: editable.elements,
    );
  }

  static String _mimeOf(Uint8List b) {
    if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b.length > 11 && b[0] == 0x52 && b[1] == 0x49 && b[8] == 0x57) {
      return 'image/webp';
    }
    if (b.length > 3 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) {
      return 'image/gif';
    }
    return 'image/png';
  }
}