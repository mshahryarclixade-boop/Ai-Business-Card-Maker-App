import 'package:flutter/services.dart';

import '../translations/tr_extension.dart';

/// Email and phone checks shared by every form that collects them. Both are
/// optional-aware: an empty value is "valid" here, so a form that requires the
/// field checks for empty on its own.
class InputValidators {
  InputValidators._();

  /// Longest email address allowed (RFC 5321).
  static const maxEmailLength = 254;

  /// A phone number has at most 15 digits, at least 7 to be callable.
  static const minPhoneDigits = 7;
  static const maxPhoneDigits = 15;

  /// What can be typed in a phone field: at most [maxPhoneDigits] digits, plus
  /// "+" and the usual separators, so the text itself is a little longer.
  static const maxPhoneLength = 25;

  static final _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\.[A-Za-z]{2,}$",
  );
  static final _phoneChars = RegExp(r'^\+?[0-9\s().\-]+$');

  /// Endings that are almost always a slip of the fingers: ".con" for ".com",
  /// ".cmo", ".ocm", ".vom", ".xom", ".comm", ".coom", ".om", ".cim"...
  /// None of them is a real top-level domain.
  static const _typoTlds = {
    'con', 'cmo', 'ocm', 'vom', 'xom', 'cim', 'clm', 'cpm', 'comm', 'coom',
    'cokm', 'ney', 'nte', 'ogr', 'orgg', 'nett', 'gmail',
    'coml', 'comn', 'comk', 'comj',
  };

  /// Common misspellings of the big mail providers.
  static const _typoDomains = {
    'gmial.com', 'gmai.com', 'gmaill.com', 'gamil.com', 'gnail.com',
    'gmail.co', 'gmail.cm', 'gmal.com', 'gemail.com', 'gmeil.com',
    'hotmial.com', 'hotmal.com', 'hotmail.co', 'hotnail.com', 'homail.com',
    'yaho.com', 'yahooo.com', 'yahoo.co', 'yhoo.com', 'yahho.com',
    'outlok.com', 'outllook.com', 'outlook.co', 'iclod.com', 'icloud.co',
    'icloud.con', 'gmail.con', 'yahoo.con', 'hotmail.con', 'outlook.con',
  };

  /// True for an address whose domain looks like a typo (see above).
  static bool hasDomainTypo(String value) {
    final v = value.trim().toLowerCase();
    final at = v.lastIndexOf('@');
    if (at < 0) return false;
    final domain = v.substring(at + 1);
    if (_typoDomains.contains(domain)) return true;
    final tld = domain.split('.').last;
    return _typoTlds.contains(tld);
  }

  /// Emails are always ASCII, whatever the app language. Urdu/Arabic keyboards
  /// can insert invisible direction marks (RLM, LRM, ZWNJ...) or lookalike
  /// characters, which made valid addresses fail validation.
  static String normalizeEmail(String value) {
    const map = {
      '\uFF20': '@', '\uFE6B': '@', // fullwidth / small commercial at
      '\u06D4': '.', '\u3002': '.', '\uFF0E': '.', // Urdu full stop, etc.
      '\u060C': '.', // Arabic comma
      '\uFF0D': '-', '\u2013': '-', '\u2014': '-',
      '\uFF3F': '_',
    };
    final out = StringBuffer();
    for (final r in value.runes) {
      final ch = String.fromCharCode(r);
      if (RegExp(r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF\u061C]')
          .hasMatch(ch)) {
        continue; // invisible bidi / zero-width characters
      }
      if (map.containsKey(ch)) {
        out.write(map[ch]);
      } else if (r >= 0x0660 && r <= 0x0669) {
        out.write(r - 0x0660); // Arabic-Indic digits
      } else if (r >= 0x06F0 && r <= 0x06F9) {
        out.write(r - 0x06F0); // Extended Arabic-Indic (Urdu) digits
      } else if (r >= 0xFF21 && r <= 0xFF5A) {
        out.write(String.fromCharCode(r - 0xFF01 + 0x21)); // fullwidth ASCII
      } else {
        out.write(ch);
      }
    }
    return out.toString();
  }

  static bool isValidEmail(String value) {
    final v = normalizeEmail(value).trim();
    if (v.length > maxEmailLength || v.contains('..')) return false;
    if (v.startsWith('.') || v.contains('.@')) return false;
    return _email.hasMatch(v) && !hasDomainTypo(v);
  }

  /// [dialCode] is the separate country code, if the form has one; the number
  /// typed after it may then be shorter (the code supplies up to 3 digits).
  static bool isValidPhone(String value, {String dialCode = ''}) {
    final v = value.trim();
    if (!_phoneChars.hasMatch(v)) return false;
    if (v.length > maxPhoneLength) return false;
    final digits = v.replaceAll(RegExp(r'\D'), '').length;
    final code = dialCode.replaceAll(RegExp(r'\D'), '').length;
    if (digits < minPhoneDigits - code || digits < 4) return false;
    return digits <= maxPhoneDigits;
  }

  /// Error text for a form field, or null when empty or valid.
  static String? emailError(String value) =>
      value.trim().isEmpty || isValidEmail(value)
      ? null
      : 'profile_setup_error_email_invalid'.tr;

  static String? phoneError(String value, {String dialCode = ''}) =>
      value.trim().isEmpty || isValidPhone(value, dialCode: dialCode)
      ? null
      : 'profile_setup_error_phone_invalid'.tr;

  /// For a phone field: only phone characters, at most 15 digits.
  static List<TextInputFormatter> get phoneFormatters => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s().\-]')),
    const MaxDigitsFormatter(maxPhoneDigits),
    LengthLimitingTextInputFormatter(maxPhoneLength),
  ];

  /// For a website field: plain ASCII (same cleaning as email), no spaces.
  static List<TextInputFormatter> get websiteFormatters => [
    const EmailNormalizeFormatter(),
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
  ];

  /// For an email field: no spaces, at most [maxEmailLength].
  static List<TextInputFormatter> get emailFormatters => [
    const EmailNormalizeFormatter(),
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    LengthLimitingTextInputFormatter(maxEmailLength),
  ];
}

/// Keeps email text in plain ASCII regardless of the app language (see
/// [InputValidators.normalizeEmail]).
class EmailNormalizeFormatter extends TextInputFormatter {
  const EmailNormalizeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = InputValidators.normalizeEmail(newValue.text);
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.end.clamp(0, text.length),
      ),
    );
  }
}

/// Stops typing (or pasting) past [max] digits. Other characters (+ spaces
/// dashes) don't count. A paste that is too long is cut at the limit.
class MaxDigitsFormatter extends TextInputFormatter {
  const MaxDigitsFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = RegExp(r'\d');
    if (digits.allMatches(newValue.text).length <= max) return newValue;
    final out = StringBuffer();
    var count = 0;
    for (final ch in newValue.text.split('')) {
      if (digits.hasMatch(ch)) {
        if (count == max) continue;
        count++;
      }
      out.write(ch);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.end.clamp(0, text.length),
      ),
    );
  }
}
