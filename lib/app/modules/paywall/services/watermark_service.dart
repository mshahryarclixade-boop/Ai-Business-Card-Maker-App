import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import 'paywall_triggers.dart';
import 'usage_service.dart';

/// Free exports carry a small watermark; Pro exports do not. Only the exported
/// COPY is stamped - the saved card itself is never touched, and the export is
/// never blocked (if stamping fails, the clean original is exported).
abstract final class WatermarkService {
  /// Whether exports are stamped right now.
  static bool get applies =>
      !UsageService.to.isPro && PaywallTriggers.enabled(PaywallTrigger.watermark);

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

    final text = croText('watermark_text');
    final fontSize = (w * 0.032).clamp(10.0, 64.0);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const ui.Color(0xFFFFFFFF),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: w * 0.9);

    final padX = fontSize * 0.6;
    final padY = fontSize * 0.35;
    final rect = ui.Rect.fromLTWH(
      w - tp.width - padX * 2 - fontSize * 0.5,
      h - tp.height - padY * 2 - fontSize * 0.5,
      tp.width + padX * 2,
      tp.height + padY * 2,
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(fontSize * 0.5)),
      ui.Paint()..color = const ui.Color(0x99000000),
    );
    tp.paint(canvas, ui.Offset(rect.left + padX, rect.top + padY));

    final result = await recorder.endRecording().toImage(image.width, image.height);
    final data = await result.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

}
