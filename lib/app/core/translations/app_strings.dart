import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/widgets.dart' show Element, WidgetsBinding;
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;

import 'app_languages.dart';
import 'en_strings.dart';

/// Registry of translations, keyed by language tag (see [kLanguageAssets]).
/// Missing or unusable strings fall back to English.
abstract final class AppStrings {
  /// Built-in English, used before the JSON loads and as the last fallback.
  static const Map<String, Map<String, String>> byLanguage = {'en': enStrings};

  static const Map<String, String> assetByLanguage = kLanguageAssets;

  static const fallbackLanguage = 'en';

  static const _storageKey = 'app_language';

  /// Active language tag.
  static String language = fallbackLanguage;

  static const Map<String, String> en = enStrings;

  static final Map<String, Map<String, String>> _loaded = {};

  static List<Locale> get supportedLocales => [
    for (final tag in assetByLanguage.keys) localeOf(tag),
  ];

  /// The active language as a [Locale].
  static Locale get locale => localeOf(language);

  static bool get isRtl => kRtlLanguages.contains(locale.languageCode);

  static Locale localeOf(String tag) {
    final parts = tag.split('-');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }

  /// Bumped whenever the language changes; the app root listens to it to
  /// update the locale (and so text direction) live.
  static final ValueNotifier<String> changes = ValueNotifier(fallbackLanguage);

  /// The language the user picked, or null for "System default".
  static String? get savedChoice {
    try {
      final saved = GetStorage().read<String>(_storageKey);
      return saved != null && isSupported(saved) ? saved : null;
    } catch (_) {
      return null;
    }
  }

  /// Picks the language and loads its strings. Call once before `runApp`.
  ///
  /// A saved choice wins; otherwise ("System default") the device language
  /// is used if we ship it, else English. Nothing is saved for the default,
  /// so it keeps following the device.
  static Future<void> init() async {
    try {
      await GetStorage.init();
    } catch (_) {}
    final tag =
        savedChoice ??
        resolve(WidgetsBinding.instance.platformDispatcher.locale);
    await _use(tag);
    // Month names etc. for every shipped language (used by DateFormat).
    try {
      await initializeDateFormatting();
    } catch (_) {}
    changes.value = language;
  }

  /// Maps a device locale to a shipped language tag (English if none).
  static String resolve(Locale device) {
    var code = device.languageCode.toLowerCase();
    // Legacy / alias codes some devices report.
    code =
        const {
          'iw': 'he',
          'in': 'id',
          'tl': 'fil',
          'nb': 'no',
          'nn': 'no',
          'sh': 'sr',
        }[code] ??
        code;
    if (code == 'zh') {
      final traditional =
          device.scriptCode == 'Hant' ||
          const {'TW', 'HK', 'MO'}.contains(device.countryCode);
      return traditional ? 'zh-TW' : 'zh';
    }
    return isSupported(code) ? code : fallbackLanguage;
  }

  /// Switches the language (e.g. from the Settings picker), remembers it and
  /// updates the running app. Returns false when [tag] isn't a shipped
  /// language.
  static Future<bool> setLanguage(String tag) async {
    if (!isSupported(tag)) return false;
    try {
      await GetStorage.init();
      await GetStorage().write(_storageKey, tag);
    } catch (_) {}
    await _use(tag);
    _notify();
    return true;
  }

  /// "System default": forgets the saved choice and follows the device
  /// language again.
  static Future<void> useSystemDefault() async {
    try {
      await GetStorage.init();
      await GetStorage().remove(_storageKey);
    } catch (_) {}
    await _use(resolve(WidgetsBinding.instance.platformDispatcher.locale));
    _notify();
  }

  /// Tells the app the language changed: updates the locale and rebuilds
  /// every widget so `.tr` lookups are redone.
  static void _notify() {
    changes.value = language;
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    // Deferred to the next frame so the new locale is already applied.
    WidgetsBinding.instance.addPostFrameCallback((_) => rebuild(root));
    WidgetsBinding.instance.scheduleFrame();
  }

  static bool isSupported(String tag) => assetByLanguage.containsKey(tag);

  static Future<void> _use(String tag) async {
    await _loadAsset(fallbackLanguage);
    if (tag != fallbackLanguage) await _loadAsset(tag);
    language = tag;
  }

  static final _placeholder = RegExp(r'\{[A-Za-z0-9_]+\}');

  static Set<String> _placeholders(String s) =>
      _placeholder.allMatches(s).map((m) => m[0]!).toSet();

  /// Loads one language's JSON; a missing or invalid file is ignored. A
  /// translated string whose `{placeholders}` differ from the English one
  /// (e.g. a translated `{name}`) is dropped so English shows instead of a
  /// broken sentence.
  static Future<void> _loadAsset(String tag) async {
    final path = assetByLanguage[tag];
    if (path == null) return;
    try {
      final decoded = jsonDecode(await rootBundle.loadString(path));
      if (decoded is! Map) return;
      final out = <String, String>{};
      for (final e in decoded.entries) {
        final key = e.key as String;
        final value = e.value;
        if (value is! String || value.trim().isEmpty) continue;
        final english = enStrings[key];
        if (english == null) continue; // unknown / stray keys
        if (tag != fallbackLanguage &&
            _placeholders(value).length != _placeholders(english).length) {
          continue;
        }
        if (tag != fallbackLanguage &&
            !_placeholders(english).containsAll(_placeholders(value))) {
          continue;
        }
        out[key] = value;
      }
      _loaded[tag] = out;
    } catch (_) {}
  }

  static String lookup(String key) =>
      _loaded[language]?[key] ??
      byLanguage[language]?[key] ??
      _loaded[fallbackLanguage]?[key] ??
      byLanguage[fallbackLanguage]![key] ??
      key;
}
