import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central place to turn a font-family *name* (as picked from the Fonts
/// tab) into an actual TextStyle. "SF Pro" isn't on Google Fonts, so it
/// falls back to the platform default; every other name is fetched live
/// from Google Fonts. Wrapped in try/catch so a typo'd/unknown family
/// never crashes the canvas — it just falls back silently.
class AppFonts {
  AppFonts._();

  static TextStyle textStyle(
      String fontFamily, {
        double? fontSize,
        FontWeight? fontWeight,
        Color? color,
        double? height,
      }) {
    if (fontFamily == 'SF Pro') {
      return TextStyle(
        fontFamily: '.SF Pro Text', // iOS system font; falls back to
        // platform default on Android
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }

    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    } catch (_) {
      // Unknown family name — don't crash, just use the default style.
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }
  }
}