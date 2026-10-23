import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A look for a QR code: colours and the shape of its dots and corner eyes.
/// Every style stays dark-on-light (or light-on-dark with strong contrast)
/// so the code scans reliably.
class QrStyle {
  const QrStyle({
    required this.id,
    required this.nameKey,
    required this.foreground,
    required this.background,
    this.eyeShape = QrEyeShape.square,
    this.moduleShape = QrDataModuleShape.square,
    this.eyeColor,
  });

  final String id;

  /// Translation key of the style's name.
  final String nameKey;
  final Color foreground;
  final Color background;
  final QrEyeShape eyeShape;
  final QrDataModuleShape moduleShape;

  /// Corner eyes in their own colour (defaults to [foreground]).
  final Color? eyeColor;
}

abstract final class QrStyles {
  static const classic = QrStyle(
    id: 'classic',
    nameKey: 'qr_style_classic',
    foreground: Color(0xFF000000),
    background: Color(0xFFFFFFFF),
  );

  static const rounded = QrStyle(
    id: 'rounded',
    nameKey: 'qr_style_rounded',
    foreground: Color(0xFF3F3D9E),
    background: Color(0xFFFFFFFF),
    eyeShape: QrEyeShape.circle,
    moduleShape: QrDataModuleShape.circle,
  );

  static const dots = QrStyle(
    id: 'dots',
    nameKey: 'qr_style_dots',
    foreground: Color(0xFF1E1E24),
    background: Color(0xFFFFFFFF),
    eyeShape: QrEyeShape.circle,
    moduleShape: QrDataModuleShape.circle,
    eyeColor: Color(0xFF007AFF),
  );

  static const midnight = QrStyle(
    id: 'midnight',
    nameKey: 'qr_style_midnight',
    foreground: Color(0xFFFFFFFF),
    background: Color(0xFF111B4F),
    eyeShape: QrEyeShape.square,
    moduleShape: QrDataModuleShape.square,
    eyeColor: Color(0xFFF5A623),
  );

  static const ocean = QrStyle(
    id: 'ocean',
    nameKey: 'qr_style_ocean',
    foreground: Color(0xFF0048B3),
    background: Color(0xFFE8F1FF),
    eyeShape: QrEyeShape.circle,
    moduleShape: QrDataModuleShape.square,
  );

  static const forest = QrStyle(
    id: 'forest',
    nameKey: 'qr_style_forest',
    foreground: Color(0xFF1F6B3A),
    background: Color(0xFFEAF7EE),
    eyeShape: QrEyeShape.square,
    moduleShape: QrDataModuleShape.circle,
  );

  static const sunset = QrStyle(
    id: 'sunset',
    nameKey: 'qr_style_sunset',
    foreground: Color(0xFFB3261E),
    background: Color(0xFFFFF3E8),
    eyeShape: QrEyeShape.circle,
    moduleShape: QrDataModuleShape.circle,
    eyeColor: Color(0xFFB35F00),
  );

  static const all = [classic, rounded, dots, midnight, ocean, forest, sunset];

  /// The style with [id], or classic for an unknown/missing one.
  static QrStyle byId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => classic);
}
