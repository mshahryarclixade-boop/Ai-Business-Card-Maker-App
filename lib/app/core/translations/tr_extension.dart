import 'app_strings.dart';

/// `'key'.tr` looks the key up in the active language ([AppStrings]) and
/// falls back to English, then to the key itself, so a missing string is
/// visible rather than blank.
///
/// `'key'.trParams({'name': 'Sam'})` fills `{name}` placeholders.
///
/// Import GetX with `hide Trans` wherever this is used, or GetX's own
/// `String.tr` will be ambiguous.
extension Trans on String {
  String get tr => AppStrings.lookup(this);

  String trParams(Map<String, Object?> params) {
    var s = AppStrings.lookup(this);
    params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }
}
