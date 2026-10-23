import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../model/qr_style.dart';

/// Computing a QR code's modules is the expensive part of showing one, and
/// [QrImageView] redoes it on every rebuild. The same code is shown many times
/// (every style tile, the preview, Home, the saved list), so it is computed
/// once per payload and shared.
abstract final class _QrCache {
  static const _max = 24;
  static final _codes = LinkedHashMap<String, QrCode?>();

  static QrCode? of(String data) {
    if (_codes.containsKey(data)) {
      final hit = _codes.remove(data); // keep the most recent last
      _codes[data] = hit;
      return hit;
    }
    final result = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final code = result.isValid ? result.qrCode : null;
    _codes[data] = code;
    if (_codes.length > _max) _codes.remove(_codes.keys.first);
    return code;
  }
}

/// A QR code drawn in a [QrStyle], on that style's background.
///
/// Drawn in its own repaint layer, so animations elsewhere on the screen (a
/// pulsing button, a page swipe) don't make it repaint thousands of dots.
class StyledQr extends StatelessWidget {
  const StyledQr({
    super.key,
    required this.data,
    required this.style,
    required this.size,
    this.padding = 0,
  });

  final String data;
  final QrStyle style;
  final double size;

  /// Quiet zone inside the background colour.
  final double padding;

  @override
  Widget build(BuildContext context) {
    final code = _QrCache.of(data);
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(padding),
        color: style.background,
        child: code == null
            ? const SizedBox.shrink()
            : QrImageView.withQr(
                qr: code,
                gapless: true,
                padding: EdgeInsets.zero,
                backgroundColor: style.background,
                eyeStyle: QrEyeStyle(
                  eyeShape: style.eyeShape,
                  color: style.eyeColor ?? style.foreground,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: style.moduleShape,
                  color: style.foreground,
                ),
              ),
      ),
    );
  }
}
