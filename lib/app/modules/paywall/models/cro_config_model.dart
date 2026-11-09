import 'dart:convert';
import 'dart:developer';

/// The CRO plan's settings, delivered by Firebase Remote Config as five JSON
/// parameters. Every value has a default here that equals the plan's Option A
/// (Balanced), so before the first fetch, offline, or with a missing, empty or
/// malformed parameter the app behaves exactly as the plan says.
///
/// Parameters (all strings holding JSON, see docs/remote_config_cro.md):
///  * `cro_limits`      - free limits
///  * `cro_triggers`    - which paywall triggers are on
///  * `cro_messages`    - headlines, counters, links
///  * `cro_experiment`  - the onboarding paywall 50/50 test
///  * `cro_offers`      - first-year and returning-user offers
abstract final class CroKeys {
  static const limits = 'cro_limits';
  static const triggers = 'cro_triggers';
  static const messages = 'cro_messages';
  static const experiment = 'cro_experiment';
  static const offers = 'cro_offers';
}

/// A number from Remote Config, also when the console stored it as a string.
int _int(Object? v, int fallback) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? fallback;
  return fallback;
}

bool _bool(Object? v, bool fallback) {
  if (v is bool) return v;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  return fallback;
}

String _str(Object? v, String fallback) =>
    v is String && v.trim().isNotEmpty ? v : fallback;

Map<String, dynamic> _parse(String raw, String name) {
  if (raw.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (e) {
    log('Invalid $name JSON, using defaults: $e', name: 'CroConfig');
  }
  return const {};
}

/// Free limits (the plan's table, Option A).
class CroLimits {
  const CroLimits({
    this.scanFree = 5,
    this.scanWarningRemaining = 1,
    this.aiCardFree = 3,
    this.templatesFree = 10,
    this.bgRemoverFree = 1,
    this.clixaChatsPerWeek = 3,
    this.careerBuildLifetime = 1,
    this.careerOptimizeLifetime = 1,
    this.showCounters = true,
  });

  /// Card scans free in total.
  final int scanFree;

  /// The warning paywall shows when this many scans are left ("2nd last
  /// scan" = 1 left).
  final int scanWarningRemaining;

  /// AI card generations free in total.
  final int aiCardFree;

  /// Templates free (the first N in the list); the rest are Pro.
  final int templatesFree;

  /// Background-remover uses free in total.
  final int bgRemoverFree;

  /// Clixa AI chats per week (a rolling 7-day window).
  final int clixaChatsPerWeek;

  /// Career Studio, per lifetime.
  final int careerBuildLifetime;
  final int careerOptimizeLifetime;

  /// "3 of 5 scans used" is always shown.
  final bool showCounters;

  factory CroLimits.fromJsonString(String raw) {
    const d = CroLimits();
    final m = _parse(raw, CroKeys.limits);
    return CroLimits(
      scanFree: _int(m['scan_free'], d.scanFree).clamp(0, 1000),
      scanWarningRemaining: _int(
        m['scan_warning_remaining'],
        d.scanWarningRemaining,
      ).clamp(0, 1000),
      aiCardFree: _int(m['ai_card_free'], d.aiCardFree).clamp(0, 1000),
      templatesFree: _int(m['templates_free'], d.templatesFree).clamp(0, 1000),
      bgRemoverFree: _int(m['bg_remover_free'], d.bgRemoverFree).clamp(0, 1000),
      clixaChatsPerWeek: _int(
        m['clixa_chats_per_week'],
        d.clixaChatsPerWeek,
      ).clamp(0, 1000),
      careerBuildLifetime: _int(
        m['career_build_lifetime'],
        d.careerBuildLifetime,
      ).clamp(0, 1000),
      careerOptimizeLifetime: _int(
        m['career_optimize_lifetime'],
        d.careerOptimizeLifetime,
      ).clamp(0, 1000),
      showCounters: _bool(m['show_counters'], d.showCounters),
    );
  }
}

/// The plan's paywall triggers; each can be switched off remotely.
class CroTriggers {
  const CroTriggers([this._enabled = const {}]);

  final Map<String, bool> _enabled;

  static const tags = [
    'onboarding',
    'scan_warning',
    'scan_limit',
    'ai_limit',
    'pro_template',
    'pro_qr',
    'pro_bg',
    'watermark',
    'clixa_limit',
    'crown',
    'settings',
  ];

  /// On unless Remote Config turns it off.
  bool enabled(String tag) => _enabled[tag] ?? true;

  factory CroTriggers.fromJsonString(String raw) {
    final m = _parse(raw, CroKeys.triggers);
    return CroTriggers({
      for (final t in tags)
        if (m[t] is Map<String, dynamic>)
          t: _bool((m[t] as Map<String, dynamic>)['enabled'], true)
        else if (m[t] is bool)
          t: m[t] as bool,
    });
  }
}

/// Headlines, counters and links. English defaults; a default shown in the
/// app language through the translation key, a text changed remotely shown as
/// written.
class CroMessages {
  const CroMessages([this._m = const {}]);

  final Map<String, dynamic> _m;

  static const defaults = {
    'default_headline': 'Create and scan without limits',
    'scan_limit_headline': 'Scan unlimited cards',
    'ai_limit_headline': 'Unlimited AI cards',
    'counter_scans': '{used} of {limit} scans used',
    'counter_ai': '{used} of {limit} AI cards used',
    'counter_bg': '{used} of {limit} background removal used',
    'counter_clixa': '{used} of {limit} chats this week',
    'counter_career_build': '{used} of {limit} profile build used',
    'counter_career_optimize': '{used} of {limit} profile optimize used',
    'watermark_link': 'Remove watermark',
    'watermark_text': 'Made with AI Business Card Maker',
  };

  /// The raw text (English default or the remote override).
  String text(String key) => _str(_m[key], defaults[key] ?? key);

  /// True when [key] was changed in Remote Config (then it is shown as is).
  bool overridden(String key) =>
      _str(_m[key], defaults[key] ?? key) != (defaults[key] ?? key);

  factory CroMessages.fromJsonString(String raw) =>
      CroMessages(_parse(raw, CroKeys.messages));
}

/// The onboarding paywall A/B test.
class CroExperiment {
  const CroExperiment({this.enabled = true, this.paywallPercent = 50});

  /// While false everybody gets the paywall (no test).
  final bool enabled;

  /// Share of users who see the paywall (the rest see none).
  final int paywallPercent;

  factory CroExperiment.fromJsonString(String raw) {
    const d = CroExperiment();
    final m = _parse(raw, CroKeys.experiment);
    final o = m['onboarding_paywall'];
    final map = o is Map<String, dynamic> ? o : const <String, dynamic>{};
    return CroExperiment(
      enabled: _bool(map['enabled'], d.enabled),
      paywallPercent: _int(map['paywall_percent'], d.paywallPercent).clamp(0, 100),
    );
  }
}

/// Discount offers. Without a product id the offer never shows.
class CroOffers {
  const CroOffers({
    this.enabled = true,
    this.firstYearProductId = '',
    this.returningEnabled = true,
    this.returningDayMin = 2,
    this.returningDayMax = 3,
    this.maxPerDay = 1,
  });

  final bool enabled;

  /// The separate discounted store product (e.g. $19.99 first year). Empty =
  /// not set up: no offer is shown.
  final String firstYearProductId;
  final bool returningEnabled;

  /// The returning-user offer shows on these days after install (inclusive).
  final int returningDayMin;
  final int returningDayMax;

  /// At most this many offer dialogs per day (the plan: 1).
  final int maxPerDay;

  factory CroOffers.fromJsonString(String raw) {
    const d = CroOffers();
    final m = _parse(raw, CroKeys.offers);
    return CroOffers(
      enabled: _bool(m['enabled'], d.enabled),
      firstYearProductId: _str(m['first_year_product_id'], d.firstYearProductId).trim(),
      returningEnabled: _bool(m['returning_enabled'], d.returningEnabled),
      returningDayMin: _int(m['returning_day_min'], d.returningDayMin).clamp(1, 60),
      returningDayMax: _int(m['returning_day_max'], d.returningDayMax).clamp(1, 60),
      maxPerDay: _int(m['max_per_day'], d.maxPerDay).clamp(1, 5),
    );
  }
}

/// Everything above, as one value.
class CroConfig {
  const CroConfig({
    this.limits = const CroLimits(),
    this.triggers = const CroTriggers(),
    this.messages = const CroMessages(),
    this.experiment = const CroExperiment(),
    this.offers = const CroOffers(),
  });

  final CroLimits limits;
  final CroTriggers triggers;
  final CroMessages messages;
  final CroExperiment experiment;
  final CroOffers offers;

  /// The plan's defaults (what the app uses before anything is fetched).
  static const defaults = CroConfig();

  /// The default JSON of each parameter, for Remote Config's in-app defaults
  /// and the setup document.
  static const defaultJson = {
    CroKeys.limits: {
      'scan_free': 5,
      'scan_warning_remaining': 1,
      'ai_card_free': 3,
      'templates_free': 10,
      'bg_remover_free': 1,
      'clixa_chats_per_week': 3,
      'career_build_lifetime': 1,
      'career_optimize_lifetime': 1,
      'show_counters': true,
    },
    CroKeys.triggers: {
      'onboarding': {'enabled': true},
      'scan_warning': {'enabled': true},
      'scan_limit': {'enabled': true},
      'ai_limit': {'enabled': true},
      'pro_template': {'enabled': true},
      'pro_qr': {'enabled': true},
      'pro_bg': {'enabled': true},
      'watermark': {'enabled': true},
      'clixa_limit': {'enabled': true},
      'crown': {'enabled': true},
      'settings': {'enabled': true},
    },
    CroKeys.messages: CroMessages.defaults,
    CroKeys.experiment: {
      'onboarding_paywall': {'enabled': true, 'paywall_percent': 50},
    },
    CroKeys.offers: {
      'enabled': true,
      'first_year_product_id': '',
      'returning_enabled': true,
      'returning_day_min': 2,
      'returning_day_max': 3,
      'max_per_day': 1,
    },
  };

  static String defaultString(String key) => jsonEncode(defaultJson[key]);
}
