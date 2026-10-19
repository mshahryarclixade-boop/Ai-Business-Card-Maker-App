import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/ai_card_prompt_builder.dart';
import '../../../core/services/ai_frame_card_builder.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../core/utils/app_fonts.dart';
import '../../custom_create/model/card_element_model.dart';
import '../../template/model/template_live_data.dart';
import '../model/user_profile_data.dart';
import '../../../core/translations/tr_extension.dart';

/// Creates the user's first card (front + back) from the details entered
/// in onboarding.
///
/// The first card is always the same design for everyone — the purple wave
/// frame with logo, name, title and contact rows (and a centered logo,
/// company and website on the back) — so it is laid out from a bundled
/// layout and frame, with no AI call: instant, free, and never failing.
class FirstCardGenerator {
  /// The first card's layout (frame + positions of every detail).
  static const String layoutAsset =
      'assets/template_json/first_card/first_card.json';

  static const Size canvasSize = Size(350, 200);

  /// Saves the card to My Cards and returns its front and back images.
  ///
  /// [templateAssetPath] (a template chosen on Home that has no layout of
  /// its own) makes an AI card in that template's style instead.
  Future<List<Uint8List>> generate(
      UserProfileData data, {
        String? templateAssetPath,
        String? title,
      }) async {
    final cardTitle = title ?? 'profile_setup_first_card_default_title'.tr;
    final logo = data.hasLogo ? data.logoBytes : null;
    final details = CardDetails.fromUserProfile(data);

    final RecentDesign design;
    if (templateAssetPath == null) {
      design = await AiFrameCardBuilder.saveCard(
        await _firstCard(details, logo),
        title: cardTitle,
      );
    } else {
      final style = (await rootBundle.load(templateAssetPath)).buffer
          .asUint8List();
      design = await AiFrameCardBuilder.create(
        style: style,
        styleMime: _mimeOf(style),
        details: details,
        logo: logo,
        title: cardTitle,
      );
    }

    return [
      await design.file.readAsBytes(),
      await (design.backFile ?? design.file).readAsBytes(),
    ];
  }

  /// The bundled first-card layout, filled with [details] and [logo].
  static Future<TemplateData> _firstCard(
    CardDetails details,
    Uint8List? logo,
  ) async {
    final layout = await TemplateData.loadPath(layoutAsset);
    if (layout == null) throw StateError('First card layout missing');

    final filled = layout.filled({
      'name': details.name,
      'title': details.jobTitle,
      'company': details.company,
      'phone': details.phone,
      'email': details.email,
      'website': details.website,
    });

    File? logoFile;
    if (logo != null && logo.isNotEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      logoFile = File(
        '${dir.path}/ai_logo_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await logoFile.writeAsBytes(logo, flush: true);
    }

    // Measuring the back's texts needs their fonts.
    await AiFrameCardBuilder.loadFonts(filled.back.elements);

    return filled.withSides(
      front: TemplateSideData(
        background: filled.front.background,
        elements: _front(filled.front.elements, logoFile),
      ),
      back: TemplateSideData(
        background: filled.back.background,
        elements: _back(filled.back.elements, logoFile, layout.orientation),
      ),
    );
  }

  /// The user's logo in the logo slot; without one, the slot is dropped
  /// and everything moves up into its place.
  static List<CardElement> _front(List<CardElement> els, File? logo) {
    final slot = els.where((e) => e.field == 'logo').firstOrNull;
    if (logo != null) {
      return [
        for (final e in els)
          if (e.field == 'logo') e.copyWith(imageFile: logo) else e,
      ];
    }
    final shift = slot == null ? 0.0 : slot.height + 4;
    return [
      for (final e in els)
        if (e.field != 'logo')
          e.copyWith(position: e.position - Offset(0, shift)),
    ];
  }

  /// The back is centered: logo, company, then the website with its icon.
  /// Without a logo, the rest moves up a little.
  static List<CardElement> _back(
    List<CardElement> els,
    File? logo,
    CardOrientation orientation,
  ) {
    final width = orientation.canvasSize.width;
    const pad = 4.0; // TemplateCardCanvas's inset
    double textWidth(CardElement e) {
      final painter = TextPainter(
        text: TextSpan(
          text: e.text,
          style: AppFonts.textStyle(
            e.fontFamily,
            fontSize: e.fontSize,
            fontWeight: e.fontWeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    double centeredX(double w) => (width - w) / 2 - pad;

    final slot = els.where((e) => e.field == 'logo').firstOrNull;
    final shift = logo == null && slot != null ? slot.height / 2 : 0.0;
    final webText = els.where((e) => e.field == 'website' &&
        e.type == CardElementType.text).firstOrNull;
    const gap = 5.0;

    final out = <CardElement>[];
    for (final e in els) {
      if (e.field == 'logo') {
        if (logo != null) {
          out.add(
            e.copyWith(
              imageFile: logo,
              position: Offset(centeredX(e.width), e.position.dy),
            ),
          );
        }
        continue;
      }
      final y = e.position.dy - shift;
      if (e.field == 'website' && webText != null) {
        // Icon + text centered as one row.
        final iconW = els
            .where((i) => i.field == 'website' && i.type != CardElementType.text)
            .map((i) => i.width)
            .fold(0.0, (a, b) => a + b);
        final rowX = centeredX(iconW + gap + textWidth(webText));
        out.add(
          e.copyWith(
            position: Offset(
              e.type == CardElementType.text ? rowX + iconW + gap : rowX,
              y,
            ),
          ),
        );
        continue;
      }
      if (e.type == CardElementType.text) {
        out.add(e.copyWith(position: Offset(centeredX(textWidth(e)), y)));
      } else {
        out.add(e.copyWith(position: Offset(e.position.dx, y)));
      }
    }
    return out;
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
