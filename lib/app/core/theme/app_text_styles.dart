import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable text styles. Swap the fontFamily to 'SFPro' once the
/// font files are added under assets/fonts and registered in pubspec.yaml.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'SFPro';

  static const TextStyle splashTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
    color: AppColors.textTitle,
  );

  static const TextStyle splashSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    color: AppColors.textSubtitle,
  );
}
