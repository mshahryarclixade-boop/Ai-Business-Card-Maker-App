import 'dart:io';
import 'package:flutter/material.dart';

enum CardOrientation { portrait, landscape }

extension CardOrientationSize on CardOrientation {
  /// Canvas size for this orientation.
  Size get canvasSize {
    switch (this) {
      case CardOrientation.landscape:
        return const Size(340, 214);
      case CardOrientation.portrait:
        return const Size(214, 340);
    }
  }

  String get label {
    switch (this) {
      case CardOrientation.landscape:
        return 'Landscape';
      case CardOrientation.portrait:
        return 'Portrait';
    }
  }
}

enum CardElementType { text, image, symbol }

enum CardImageMask { none, circle, roundedSquare, hexagon, star, cloud1, cloud2 }

extension CardImageMaskLabel on CardImageMask {
  String get label {
    switch (this) {
      case CardImageMask.none:
        return 'None';
      case CardImageMask.circle:
        return 'Circle';
      case CardImageMask.roundedSquare:
        return 'Square';
      case CardImageMask.hexagon:
        return 'Hexagon';
      case CardImageMask.star:
        return 'Star';
      case CardImageMask.cloud1:
        return 'Cloud';
      case CardImageMask.cloud2:
        return 'Cloud+';
    }
  }
}
class CardElement {
  final String id;
  final CardElementType type;
  Offset position; // top-left, in canvas-local coordinates
  double rotation; // radians, reserved for future use

  // ---- text-only fields ----
  String text;
  String fontFamily;
  double fontSize;
  Color color;
  FontWeight fontWeight;

  // ---- image-only fields ----
  File? imageFile;

  /// Bundled asset image (template logos). Used when [imageFile] is null.
  String? imageAsset;

  double width;
  double height;

  CardImageMask imageMask;

  String symbol;

  IconData? iconData;

  String? iconAsset;

  Color tintColor;

  double opacity;

  String? field;

  bool italic;


  CardElement({
    required this.id,
    required this.type,
    required this.position,
    this.rotation = 0,
    this.text = '',
    this.fontFamily = 'SF Pro',
    this.fontSize = 18,
    this.color = const Color(0xFF1E1E24),
    this.fontWeight = FontWeight.w400,
    this.imageFile,
    this.imageAsset,
    this.width = 80,
    this.height = 80,
    this.imageMask = CardImageMask.none,
    this.symbol = '',
    this.iconData,
    this.iconAsset,
    this.tintColor = const Color(0xFF1E1E24),
    this.opacity = 1.0,
    this.field,
    this.italic = false,
  });

  factory CardElement.text({
    required String id,
    required Offset position,
    String text = 'Double tap to edit',
  }) {
    return CardElement(
      id: id,
      type: CardElementType.text,
      position: position,
      text: text,
    );
  }

  factory CardElement.image({
    required String id,
    required Offset position,
    required File file,
    double width = 90,
    double height = 90,
  }) {
    return CardElement(
      id: id,
      type: CardElementType.image,
      position: position,
      imageFile: file,
      width: width,
      height: height,
    );
  }

  /// Image that comes from a bundled asset (e.g. a template logo).
  factory CardElement.assetImage({
    required String id,
    required Offset position,
    required String asset,
    double width = 60,
    double height = 60,
  }) {
    return CardElement(
      id: id,
      type: CardElementType.image,
      position: position,
      imageAsset: asset,
      width: width,
      height: height,
    );
  }

  factory CardElement.symbol({
    required String id,
    required Offset position,
    required String symbol,
  }) {
    return CardElement(
      id: id,
      type: CardElementType.symbol,
      position: position,
      symbol: symbol,
      width: 36,
      height: 36,
    );
  }

  factory CardElement.sticker({
    required String id,
    required Offset position,
    IconData? iconData,
    String? iconAsset,
    double width = 36,
    double height = 36,
    Color tintColor = const Color(0xFF1E1E24),
  }) {
    assert(iconData != null || iconAsset != null,
    'CardElement.sticker needs an iconData or an iconAsset');
    return CardElement(
      id: id,
      type: CardElementType.symbol,
      position: position,
      iconData: iconData,
      iconAsset: iconAsset,
      width: width,
      height: height,
      tintColor: tintColor,
    );
  }

  CardElement copyWith({
    Offset? position,
    double? rotation,
    String? text,
    String? fontFamily,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    File? imageFile,
    String? imageAsset,
    double? width,
    double? height,
    CardImageMask? imageMask,
    String? symbol,
    IconData? iconData,
    String? iconAsset,
    Color? tintColor,
    double? opacity,
    String? field,
    bool? italic,

  }) {
    return CardElement(
      id: id,
      type: type,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      fontWeight: fontWeight ?? this.fontWeight,
      imageFile: imageFile ?? this.imageFile,
      imageAsset: imageAsset ?? this.imageAsset,
      width: width ?? this.width,
      height: height ?? this.height,
      imageMask: imageMask ?? this.imageMask,
      symbol: symbol ?? this.symbol,
      iconData: iconData ?? this.iconData,
      iconAsset: iconAsset ?? this.iconAsset,
      tintColor: tintColor ?? this.tintColor,
      opacity: opacity ?? this.opacity,
      field: field ?? this.field,
      italic: italic ?? this.italic,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'position': {'dx': position.dx, 'dy': position.dy},
    'rotation': rotation,
    'text': text,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'color': color.toARGB32(),
    'fontWeight': fontWeight.index,
    'imageFilePath': imageFile?.path,
    'imageAsset': imageAsset,
    'width': width,
    'height': height,
    'imageMask': imageMask.name,
    'symbol': symbol,
    'iconCodePoint': iconData?.codePoint,
    'iconFontFamily': iconData?.fontFamily,
    'iconFontPackage': iconData?.fontPackage,
    'iconAsset': iconAsset,
    'tintColor': tintColor.toARGB32(),
    'opacity': opacity,
    'field': field,
    'italic': italic,

  };

  factory CardElement.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>;
    return CardElement(
      id: json['id'] as String,
      type: CardElementType.values.byName(json['type'] as String),
      position: Offset(
        (pos['dx'] as num).toDouble(),
        (pos['dy'] as num).toDouble(),
      ),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      text: json['text'] as String? ?? '',
      fontFamily: json['fontFamily'] as String? ?? 'SF Pro',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      color: Color(json['color'] as int? ?? 0xFF1E1E24),
      fontWeight:
      FontWeight.values[json['fontWeight'] as int? ?? FontWeight.w400.index],
      imageFile: json['imageFilePath'] != null
          ? File(json['imageFilePath'] as String)
          : null,
      imageAsset: json['imageAsset'] as String?,
      width: (json['width'] as num?)?.toDouble() ?? 80,
      height: (json['height'] as num?)?.toDouble() ?? 80,
      imageMask:
      CardImageMask.values.byName(json['imageMask'] as String? ?? 'none'),
      symbol: json['symbol'] as String? ?? '',
      iconData: json['iconCodePoint'] != null
          ? IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      )
          : null,
      iconAsset: json['iconAsset'] as String?,
      tintColor: Color(json['tintColor'] as int? ?? 0xFF1E1E24),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      field: json['field'] as String?,
      italic: json['italic'] as bool? ?? false,
    );
  }
}

const List<String> kSampleFontFamilies = [
  'SF Pro', // system default
  'Share Tech',
  'Shippori Antique B1',
  'Single Day',
  'Sigmar One',
  'Simonetta',
  'Shadows Into Light Two',
  'Tangerine',
];

const List<double> kSampleFontSizes = [10, 18, 20, 22, 24, 36, 48, 64];

/// Preset swatches shown in the "Color" tab, left to right / row by row.
const List<Color> kPresetColors = [
  Color(0xFF4A4A4A),
  Color(0xFFFFC542),
  Color(0xFF3DDC84),
  Color(0xFF2E7D32),
  Color(0xFFE53935),
  Color(0xFF2196F3),
  Color(0xFF8E1B3C),
  Color(0xFF00897B),
  Color(0xFFEC407A),
  Color(0xFF7B1FA2),
];

/// A tiny fixed symbol/emoji set for the "Symbols" tool.
const List<String> kSampleSymbols = [
  '★', '✓', '♥', '➤', '☎', '✉', '⚑', '☀',
  '✦', '⬤', '◆', '⬥', '☺', '⚡', '❖', '➜',
];