import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';

import '../model/qr_code_builder.dart';
import '../model/qr_profile_data.dart';

class QrGeneratorService {
  /// Build the vCard payload for a profile. Exposed separately so the
  /// UI can e.g. show/copy the raw payload if needed for debugging.
  String payloadFor(QrProfileData profile) => buildVCard(profile);

  /// [size] is the final image size, including the white border.
  /// [borderFraction] is the border width as a share of [size]
  /// (0.08 = 8% on every side).
  Future<Uint8List> generatePngBytes(
      QrProfileData profile, {
        double size = 1024,
        double borderFraction = 0.08,
        ui.Color foregroundColor = const ui.Color(0xFF000000),
        ui.Color backgroundColor = const ui.Color(0xFFFFFFFF),
      }) async {
    final data = payloadFor(profile);

    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: foregroundColor,
      emptyColor: backgroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    final border = size * borderFraction;
    final qrSize = size - border * 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // White background for the whole image (this becomes the border).
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size, size),
      ui.Paint()..color = backgroundColor,
    );

    // Draw the QR inside, pushed in by the border.
    canvas.translate(border, border);
    painter.paint(canvas, ui.Size(qrSize, qrSize));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final imageData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (imageData == null) {
      throw Exception('QR generation failed: could not render image data.');
    }

    return imageData.buffer.asUint8List();
  }
}