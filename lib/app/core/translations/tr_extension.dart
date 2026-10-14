import 'app_strings.dart';

/// `'key'.tr` — looks the key up in [AppStrings]; falls back to the key
/// itself so a missing translation is visible rather than blank.
///
/// Import GetX with `hide Trans` wherever this is used, or GetX's own
/// `String.tr` will be ambiguous.
extension Trans on String {
  String get tr => AppStrings.en[this] ?? this;
}
