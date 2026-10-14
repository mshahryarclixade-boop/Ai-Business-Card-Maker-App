import 'dart:convert';

/// Credit pool granted per plan tier. `-1` means unlimited.
class CreditPools {
  const CreditPools({
    this.free = 5,
    this.trial = 50,
    this.weekly = 50,
    this.monthly = 200,
    this.yearly = 2000,
  });

  final int free;
  final int trial;
  final int weekly;
  final int monthly;
  final int yearly;

  /// Pool for a tier name from `planTierForProduct` (or `free`).
  int forTier(String tier) => switch (tier) {
    'trial' => trial,
    'weekly' => weekly,
    'monthly' => monthly,
    'yearly' => yearly,
    _ => free,
  };

  factory CreditPools.fromJson(Map<String, dynamic> json) {
    const d = CreditPools();
    int pick(String key, int fallback) =>
        (json[key] as num?)?.toInt() ?? fallback;
    return CreditPools(
      free: pick('free', d.free),
      trial: pick('trial', d.trial),
      weekly: pick('weekly', d.weekly),
      monthly: pick('monthly', d.monthly),
      yearly: pick('yearly', d.yearly),
    );
  }

  /// Parses a Remote Config JSON string; any problem yields the defaults.
  factory CreditPools.fromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return CreditPools.fromJson(decoded);
    } catch (_) {}
    return const CreditPools();
  }
}

/// What each action costs, in credits.
class CreditCosts {
  const CreditCosts({this.aiCard = 1, this.export = 0});

  final int aiCard;
  final int export;

  factory CreditCosts.fromJson(Map<String, dynamic> json) {
    const d = CreditCosts();
    return CreditCosts(
      aiCard: (json['ai_card'] as num?)?.toInt() ?? d.aiCard,
      export: (json['export'] as num?)?.toInt() ?? d.export,
    );
  }

  factory CreditCosts.fromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return CreditCosts.fromJson(decoded);
    } catch (_) {}
    return const CreditCosts();
  }
}
