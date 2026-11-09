import 'dart:math';

import 'package:get_storage/get_storage.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../models/cro_config_model.dart';
import 'paywall_triggers.dart';
import 'usage_service.dart';

/// The onboarding paywall 50/50 test: each user is put in a group ONCE (kept on
/// the device); the "paywall" group sees the skippable paywall before
/// "Go to Home", the "control" group goes straight to Home.
class OnboardingExperiment {
  OnboardingExperiment({
    GetStorage? box,
    CroExperiment Function()? config,
    Random? random,
    bool Function()? isPro,
  }) : _box = box ?? GetStorage(),
       _config = config ?? (() => RemoteConfigService().croExperiment),
       _random = random ?? Random(),
       _isPro = isPro ?? (() => UsageService.to.isPro);

  static const storageKey = 'cro_onboarding_variant';
  static const paywallGroup = 'paywall';
  static const controlGroup = 'control';

  final GetStorage _box;
  final CroExperiment Function() _config;
  final Random _random;
  final bool Function() _isPro;

  /// This user's group. With the test switched off everybody is in "paywall".
  String variant() {
    final cfg = _config();
    if (!cfg.enabled) return paywallGroup;
    final saved = _box.read<String>(storageKey);
    if (saved == paywallGroup || saved == controlGroup) return saved!;
    final v = _random.nextInt(100) < cfg.paywallPercent ? paywallGroup : controlGroup;
    _box.write(storageKey, v);
    AnalyticsService.logExperimentAssigned(
      experiment: 'onboarding_paywall',
      variant: v,
    );
    return v;
  }

  /// Whether the paywall shows before Home.
  bool get showsPaywall =>
      !_isPro() &&
      PaywallTriggers.enabled(PaywallTrigger.onboarding) &&
      variant() == paywallGroup;
}
