import 'dart:convert';

import '../../../core/translations/tr_extension.dart';
import '../../../core/utils/localized_text.dart';

/// The onboarding screen's Remote Config (`onboarding_config`):
/// `enabled`, `title`, `subtitle`, `button_text`.
///
/// A text equal to the English default is shown in the app language (its
/// translation key); a text changed in Remote Config is shown as written. An
/// empty or missing value keeps the built-in text.
class OnboardingConfig {
  const OnboardingConfig._(this._m);

  final Map<String, dynamic> _m;

  static const titleDefault = 'Create Stunning\nCards in Seconds.';
  static const buttonDefault = 'Create my Profile';

  factory OnboardingConfig.fromJsonString(String raw) {
    if (raw.trim().isEmpty) return const OnboardingConfig._({});
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return OnboardingConfig._(d);
    } catch (_) {}
    return const OnboardingConfig._({});
  }

  /// Null when not set (the caller then uses the old `onboarding_enabled`).
  bool? get enabled {
    final v = _m['enabled'];
    if (v is bool) return v;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    return null;
  }

  String _text(String key, String english, String trKey) {
    final raw = _m[key];
    final v = raw is Map ? pickLocalized(raw) : raw;
    if (v is! String || v.trim().isEmpty || v == english) return trKey.tr;
    return v;
  }

  String get title =>
      _text('title', titleDefault, 'onboarding_page1_heading');
  String get buttonText =>
      _text('button_text', buttonDefault, 'onboarding_create_profile');

  /// Shown under the title only when set (the screen has none by default).
  String get subtitle {
    final raw = _m['subtitle'];
    final v = raw is Map ? pickLocalized(raw) : raw;
    return v is String ? v.trim() : '';
  }
}
