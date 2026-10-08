import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  AppFonts._();

  static TextStyle textStyle(
      String fontFamily, {
        double? fontSize,
        FontWeight? fontWeight,
        FontStyle? fontStyle,
        Color? color,
        double? height,
      }) {
    if (fontFamily == 'SF Pro') {
      return TextStyle(
        fontFamily: '.SF Pro Text', // iOS system font; falls back to
        // platform default on Android
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        height: height,
      );
    }

    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        height: height,
      );
    } catch (_) {
      // Unknown family name — don't crash, just use the default style.
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        height: height,
      );
    }
  }
}