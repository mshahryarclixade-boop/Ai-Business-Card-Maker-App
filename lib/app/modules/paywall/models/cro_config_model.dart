import 'dart:convert';
import 'dart:developer';

import '../../../core/utils/localized_text.dart';

/// The CRO plan's settings, delivered by Firebase Remote Config as JSON
/// parameters. Every value has a default here that equals the plan's Option A
/// (Balanced), so before the first fetch, offline, or with a missing, empty or
/// malformed parameter the app behaves exactly as the plan says.
///
/// Parameters (all strings holding JSON, see docs/remote_config_cro.md):
///  * `cro_limits`      - free limits
///  * `cro_triggers`    - which paywall triggers are on
///  * `cro_messages`    - headlines, counters, links
///  * `cro_experiment`  - the onboarding paywall 50/50 test
abstract final class CroKeys {
  static const limits = 'cro_limits';
  static const triggers = 'cro_triggers';
  static const messages = 'cro_messages';
  static const experiment = 'cro_experiment';

  /// Free + paid limits per plan. Wins over `cro_limits` when it is set
  /// (`cro_limits` stays as the fallback for old values).
  static const planLimits = 'plan_limits';

  /// Store product ids of the two plans sold + the free-trial switch.
  static const paywallOffers = 'paywall_offers';
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
    this.clixaChatsPerWeek = 3,
    this.careerBuildLifetime = 1,
    this.careerOptimizeLifetime = 1,
    this.showCounters = true,
    this.clixaChatsPerWeekPro = 5,
  });

  /// Card scans free in total.
  final int scanFree;

  /// The warning paywall shows when this many scans are left ("2nd last
  /// scan" = 1 left).
  final int scanWarningRemaining;

  /// AI card generations free in total.
  final int aiCardFree;

  /// The first N templates are free, the rest are Pro. Fixed in the app (no
  /// Remote Config): not a usage limit.
  static const int freeTemplates = 10;

  /// Clixa AI chats per week (a rolling 7-day window).
  final int clixaChatsPerWeek;

  /// Career Studio, per lifetime.
  final int careerBuildLifetime;
  final int careerOptimizeLifetime;

  /// "3 of 5 scans used" is always shown.
  final bool showCounters;

  /// Clixa AI chats per week for Pro users (5 unless `plan_limits` says
  /// otherwise; -1 = unlimited).
  final int clixaChatsPerWeekPro;

  /// The paid plan tiers `plan_limits` may list. `weekly` is not sold any
  /// more but is read when present; a weekly subscriber without a `weekly`
  /// entry gets the same as the other paid tiers (they are read together).
  static const paidTiers = ['trial', 'weekly', 'monthly', 'yearly'];

  /// Reads `plan_limits` (free plan -> the free limits; paid plans -> the
  /// Pro Clixa allowance). Null when the JSON has no usable `plans.free`, so
  /// the caller falls back to `cro_limits`.
  static CroLimits? fromPlanLimitsString(String raw) {
    final m = _parse(raw, CroKeys.planLimits);
    final plans = m['plans'];
    final free = plans is Map ? plans['free'] : null;
    if (free is! Map) return null;
    const d = CroLimits();

    int lim(String feature, int fallback) {
      final f = free[feature];
      return f is Map ? _int(f['limit'], fallback).clamp(0, 1000) : fallback;
    }

    final scans = free['card_scans'];
    final clixa = free['clixa_chats'];
    // Pro Clixa: the highest value across the paid tiers present (-1 =
    // unlimited is the highest). None present: unlimited.
    int? pro;
    for (final tier in paidTiers) {
      final t = plans[tier];
      final c = t is Map ? t['clixa_chats'] : null;
      if (c is! Map) continue;
      final v = _int(c['limit'], -1);
      if (v < 0) {
        pro = -1;
        break;
      }
      pro = pro == null || v > pro ? v : pro;
    }
    return CroLimits(
      scanFree: lim('card_scans', d.scanFree),
      scanWarningRemaining: scans is Map
          ? _int(scans['warn_at_remaining'], d.scanWarningRemaining).clamp(0, 1000)
          : d.scanWarningRemaining,
      aiCardFree: lim('ai_card', d.aiCardFree),
      clixaChatsPerWeek: clixa is Map
          ? _int(clixa['limit'], d.clixaChatsPerWeek).clamp(0, 1000)
          : d.clixaChatsPerWeek,
      careerBuildLifetime: lim('career_build', d.careerBuildLifetime),
      careerOptimizeLifetime: lim('career_optimize', d.careerOptimizeLifetime),
      showCounters: _bool(m['show_counters'], d.showCounters),
      clixaChatsPerWeekPro: pro ?? d.clixaChatsPerWeekPro,
    );
  }

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
    'scan_limit_headline': 'Keep scanning with Pro',
    'ai_limit_headline': 'Keep creating with AI',
    'tools_headline': 'Grow your business with Pro',
    'pro_template_headline': 'Unlock every template',
    'pro_qr_headline': 'Unlock every QR style',
    'watermark_headline': 'Export without the watermark',
    'clixa_limit_headline': 'Keep talking to your AI coach',
    'expert_panel_headline': 'Pitch to your AI expert panel',
    'career_headline': 'Get found by the right people',
    'counter_scans': '{used} of {limit} scans used',
    'counter_ai': '{used} of {limit} AI cards used',
    'counter_clixa': '{used} of {limit} chats this week',
    'counter_career_build': '{used} of {limit} profile build used',
    'counter_career_optimize': '{used} of {limit} profile optimize used',
    'watermark_link': 'Remove watermark',
    'watermark_text': 'Made with Business Card Maker',
  };

  /// A value may be a string or a map of texts per language.
  Object? _value(String key) {
    final v = _m[key];
    return v is Map ? pickLocalized(v) : v;
  }

  /// The raw text (English default or the remote override), in the app's
  /// language when the override is a per-language map.
  String text(String key) => _str(_value(key), defaults[key] ?? key);

  /// True when [key] was changed in Remote Config (then it is shown as is).
  bool overridden(String key) =>
      _str(_value(key), defaults[key] ?? key) != (defaults[key] ?? key);

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

/// `paywall_offers`: the store products of the plans sold (yearly, monthly)
/// and the free-trial settings. Every field is optional; a missing one keeps
/// the app's built-in value (product ids in `RevenueCatHelper`, trial in
/// `paywall_config.trial`). There are no discount or returning-user offers.
class PaywallOffers {
  const PaywallOffers({
    this.yearlyProductId,
    this.monthlyProductId,
    this.trialEnabled,
    this.trialDays,
  });

  final String? yearlyProductId;
  final String? monthlyProductId;

  /// Null = not set here (then `paywall_config.trial.enabled` decides).
  final bool? trialEnabled;

  /// The trial length shown until the store reports the real one.
  final int? trialDays;

  factory PaywallOffers.fromJsonString(String raw) {
    final m = _parse(raw, CroKeys.paywallOffers);
    final products = m['products'] is Map ? m['products'] as Map : const {};
    final trial = m['trial'] is Map ? m['trial'] as Map : const {};
    String? id(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    final days = trial['days'];
    final parsedDays = days is num
        ? days.toInt()
        : (days is String ? int.tryParse(days.trim()) : null);
    final enabled = trial['enabled'];
    return PaywallOffers(
      yearlyProductId: id(products['yearly']),
      monthlyProductId: id(products['monthly']),
      trialEnabled: enabled is bool ? enabled : null,
      trialDays: parsedDays != null && parsedDays > 0 ? parsedDays : null,
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
  });

  final CroLimits limits;
  final CroTriggers triggers;
  final CroMessages messages;
  final CroExperiment experiment;

  /// The plan's defaults (what the app uses before anything is fetched).
  static const defaults = CroConfig();

  /// The default JSON of each parameter, for Remote Config's in-app defaults
  /// and the setup document.
  static const defaultJson = {
    CroKeys.limits: {
      'scan_free': 5,
      'scan_warning_remaining': 1,
      'ai_card_free': 3,
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
      'watermark': {'enabled': true},
      'clixa_limit': {'enabled': true},
      'crown': {'enabled': true},
      'settings': {'enabled': true},
    },
    CroKeys.messages: CroMessages.defaults,
    CroKeys.experiment: {
      'onboarding_paywall': {'enabled': true, 'paywall_percent': 50},
    },
  };

  static String defaultString(String key) => jsonEncode(defaultJson[key]);
}
