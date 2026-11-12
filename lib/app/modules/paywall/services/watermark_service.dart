import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/remote_config_service.dart';
import '../widgets/pro_dialogs.dart';
import 'paywall_triggers.dart';
import 'usage_service.dart';

/// Free exports carry a small watermark; Pro exports do not. Only the exported
/// COPY is stamped - the saved card itself is never touched, and the export is
/// never blocked (if stamping fails, the clean original is exported).
abstract final class WatermarkService {
  /// The watermark's text: exactly "Made with Business Card Maker" (a text set
  /// in Remote Config wins; the old "...with AI Business Card Maker" default
  /// that was published earlier does not).
  static const defaultText = 'Made with Business Card Maker';
  /// The text as shown: "Made with Business" / "Card Maker" on two lines (any
  /// other text set in Remote Config is shown as written).
  static String get lines {
    final t = text;
    return t == defaultText ? 'Made with Business\nCard Maker' : t;
  }

  static String get text {
    final t = RemoteConfigService().croMessages.text('watermark_text');
    return t == 'Made with AI Business Card Maker' ? defaultText : t;
  }

  /// Whether exports are stamped right now.
  static bool get applies =>
      !UsageService.to.isPro && PaywallTriggers.enabled(PaywallTrigger.watermark);

  /// The export gate for Save / Share on Home. Pro users (and a watermark
  /// switched off remotely) pass straight through. A free user is asked:
  ///  * "No": the export goes ahead WITH the watermark (true);
  ///  * "Yes": the watermark paywall opens; the export is clean only if they
  ///    became Pro there, and it does NOT happen at all if they closed the
  ///    paywall (false) - never a clean export without Pro.
  /// Front and back are exported together after this single answer.
  static Future<bool> confirmExport({String? screen}) async {
    if (!applies) return true;
    if (!await showWatermarkExportDialog()) return true; // keep watermark
    final pro = await PaywallTriggers.show(PaywallTrigger.watermark, screen: screen);
    return pro;
  }

  /// The files to export: stamped copies for free users, [paths] for Pro.
  static Future<List<String>> prepare(List<String> paths) async {
    if (!applies) return paths;
    final out = <String>[];
    for (final p in paths) {
      try {
        out.add(await _stamp(p));
      } catch (_) {
        out.add(p);
      }
    }
    return out;
  }

  /// The same for an image already in memory (the profile card capture).
  static Future<Uint8List> prepareBytes(Uint8List bytes) async {
    if (!applies) return bytes;
    try {
      return await _stampBytes(bytes);
    } catch (_) {
      return bytes;
    }
  }

  static Future<String> _stamp(String path) async {
    final stamped = await _stampBytes(await File(path).readAsBytes());
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/wm_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(stamped);
    return file.path;
  }

  static Future<Uint8List> _stampBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    final w = image.width.toDouble();
    final h = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    // The same mark as on the previews: a small grey crown and the text,
    // top-right (no box).
    final font = (w * 0.03).clamp(8.0, 64.0);
    const grey = ui.Color(0xFFA3A3AE);
    final crownIcon = FontAwesomeIcons.crown;
    final crown = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(crownIcon.codePoint),
        style: TextStyle(
          fontFamily: crownIcon.fontFamily,
          package: crownIcon.fontPackage,
          fontSize: font * 1.45,
          color: grey,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final tp = TextPainter(
      text: TextSpan(
        text: lines,
        style: TextStyle(color: grey, fontSize: font, height: 1.2, fontWeight: FontWeight.w500),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: w * 0.46 - crown.width - font * 0.55);
    final gap = font * 0.55;
    final blockW = crown.width + gap + tp.width;
    final blockH = tp.height > crown.height ? tp.height : crown.height;
    final left = w - w * 0.045 - blockW;
    final top = w * 0.04;
    crown.paint(canvas, ui.Offset(left, top + (blockH - crown.height) / 2));
    tp.paint(canvas, ui.Offset(left + crown.width + gap, top + (blockH - tp.height) / 2));

    final result = await recorder.endRecording().toImage(image.width, image.height);
    final data = await result.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

}
