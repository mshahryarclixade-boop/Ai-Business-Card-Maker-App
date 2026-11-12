import '../translations/app_strings.dart';

/// A Remote Config text may be a plain string (shown as written, in every
/// language) or a map of texts per language:
///
///     "title": {"default": "Monthly", "fr": "Mensuel", "ar": "شهري"}
///
/// Picks the entry for the app's language (exact tag like `pt-BR`, then the
/// language code `pt`), then `default`, then `en`. Null when none is usable.
String? pickLocalized(Map<dynamic, dynamic> texts) {
  String? text(Object? k) {
    final v = texts[k];
    return v is String && v.trim().isNotEmpty ? v : null;
  }

  final tag = AppStrings.language;
  final code = tag.split(RegExp('[-_]')).first;
  return text(tag) ??
      text(tag.replaceAll('-', '_')) ??
      text(code) ??
      text('default') ??
      text('en');
}
