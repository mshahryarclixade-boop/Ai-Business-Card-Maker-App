import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:qr_flutter/qr_flutter.dart';

import '../model/qr_code_builder.dart';
import '../model/qr_profile_data.dart';


class QrGeneratorService {
  /// Build the vCard payload for a profile. Exposed separately so the
  /// UI can e.g. show/copy the raw payload if needed for debugging.
  String payloadFor(QrProfileData profile) => buildVCard(profile);

  Future<Uint8List> generatePngBytes(
      QrProfileData profile, {
        double size = 1024,
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

    final imageData = await painter.toImageData(
      size,
      format: ui.ImageByteFormat.png,
    );

    if (imageData == null) {
      throw Exception('QR generation failed: could not render image data.');
    }

    return imageData.buffer.asUint8List();
  }
}