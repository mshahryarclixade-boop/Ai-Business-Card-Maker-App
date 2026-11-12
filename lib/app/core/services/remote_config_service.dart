import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../../modules/paywall/models/credit_config_model.dart';
import '../../modules/paywall/models/cro_config_model.dart';
import '../../modules/onboarding/models/onboarding_config.dart';
import '../../modules/paywall/models/paywall_config_model.dart';

/// Remote Config values, with safe in-app defaults so the app behaves the
/// same before the first fetch or when offline.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService _instance = RemoteConfigService._();
  factory RemoteConfigService() => _instance;

  static const _creditsEnabledKey = 'credits_enabled';
  static const _creditPoolsKey = 'credit_pools';
  static const _creditCostsKey = 'credit_costs';
  static const _onboardingEnabledKey = 'onboarding_enabled';
  static const _paywallConfigKey = 'paywall_config';
  static const _scanOrientationToggleKey = 'scan_orientation_toggle';
  static const _onboardingConfigKey = 'onboarding_config';

  // One JSON parameter per platform: android_version_config /
  // ios_version_config.
  static String get _versionConfigKey =>
      Platform.isIOS ? 'ios_version_config' : 'android_version_config';

  FirebaseRemoteConfig? _rc;

  // Parsed-config cache: re-parse only when the raw JSON changes.
  String? _paywallRaw;
  PaywallConfig? _paywallConfig;

  Future<void>? _fetch;

  /// Completes when the startup fetch+activate has finished (or failed), so
  /// callers can read fresh values. [init] itself may be cut short by the
  /// caller's timeout while this fetch keeps running.
  Future<void> whenFetched() => _fetch ?? Future<void>.value();

  Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          // Debug builds refetch every launch so Console changes show up.
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await rc.setDefaults({
        _creditsEnabledKey: false,
        _creditPoolsKey: '',
        _creditCostsKey: '',
        _paywallConfigKey: jsonEncode(PaywallConfig.defaultJson),
        'android_version_config': '',
        'ios_version_config': '',
        _onboardingEnabledKey: true,
        // No in-app default for plan_limits: until it is published,
        // cro_limits keeps working.
        CroKeys.planLimits: '',
        CroKeys.paywallOffers: '',
        _onboardingConfigKey: '',
        _scanOrientationToggleKey: false,
        // The CRO plan (limits, triggers, messages, experiment).
        for (final k in CroConfig.defaultJson.keys)
          k: CroConfig.defaultString(k),
      });
      _rc = rc;
      final fetch = rc.fetchAndActivate();
      _fetch = fetch.then((_) {}, onError: (_) {});
      await fetch;
    } catch (e) {
      log(
        'Remote Config init failed, using defaults: $e',
        name: 'RemoteConfigService',
      );
    }
  }

  /// Raw JSON of this platform's version config ('' when not delivered).
  String get versionConfigRaw => _rc?.getString(_versionConfigKey) ?? '';

  /// Fetch status and where the version config came from (remote / default)
  /// — for the debug log only.
  String get versionDebugInfo {
    final rc = _rc;
    if (rc == null) return 'remote config not initialised';
    return 'fetchStatus=${rc.lastFetchStatus.name} '
        '$_versionConfigKey=${rc.getValue(_versionConfigKey).source.name}';
  }

  /// Master switch: while false, the credit gate lets everything through.
  bool get creditsEnabled => _rc?.getBool(_creditsEnabledKey) ?? false;
  /// While false, the app skips onboarding. Defaults to true, so a failed
  /// or slow fetch keeps the current behaviour.
  /// The scan screen's Auto / Landscape / Portrait switch. Hidden by default
  /// (the card is detected automatically).
  bool get scanOrientationToggle =>
      _rc?.getBool(_scanOrientationToggleKey) ?? false;

  /// The onboarding screen's settings (`onboarding_config`). `enabled` falls
  /// back to the old `onboarding_enabled` while the new key is not set.
  OnboardingConfig get onboardingConfig => OnboardingConfig.fromJsonString(
    _rc?.getString(_onboardingConfigKey) ?? '',
  );

  bool get onboardingEnabled =>
      onboardingConfig.enabled ??
      (_rc?.getBool(_onboardingEnabledKey) ?? true);

  /// Paywall copy + display settings. Never null: falls back to the
  /// built-in defaults when RC is unavailable or the JSON is invalid.
  PaywallConfig get paywallConfig {
    final raw = _rc?.getString(_paywallConfigKey) ?? '';
    if (_paywallConfig == null || raw != _paywallRaw) {
      _paywallRaw = raw;
      _paywallConfig = PaywallConfig.fromJsonString(raw);
    }
    return _paywallConfig!;
  }

  // ---- CRO plan ------------------------------------------------------------
  // Parsed per raw value and cached: a getter is cheap to call anywhere. Every
  // one falls back to the plan's defaults (not fetched yet, offline, bad JSON).
  final Map<String, (String, Object)> _croCache = {};

  T _cro<T extends Object>(String key, T Function(String raw) parse) {
    final raw = _rc?.getString(key) ?? '';
    final hit = _croCache[key];
    if (hit != null && hit.$1 == raw) return hit.$2 as T;
    final value = parse(raw);
    _croCache[key] = (raw, value);
    return value;
  }

  PaywallOffers get paywallOffers =>
      _cro(CroKeys.paywallOffers, PaywallOffers.fromJsonString);

  String? _planRaw;
  CroLimits? _planLimits;

  /// `plan_limits` when published, else the older `cro_limits`.
  CroLimits get croLimits {
    final raw = _rc?.getString(CroKeys.planLimits) ?? '';
    if (raw.trim().isNotEmpty) {
      if (raw != _planRaw) {
        _planRaw = raw;
        _planLimits = CroLimits.fromPlanLimitsString(raw);
      }
      final plan = _planLimits;
      if (plan != null) return plan;
    }
    return _cro(CroKeys.limits, CroLimits.fromJsonString);
  }
  CroTriggers get croTriggers =>
      _cro(CroKeys.triggers, CroTriggers.fromJsonString);
  CroMessages get croMessages =>
      _cro(CroKeys.messages, CroMessages.fromJsonString);
  CroExperiment get croExperiment =>
      _cro(CroKeys.experiment, CroExperiment.fromJsonString);

  CreditPools get creditPools =>
      CreditPools.fromJsonString(_rc?.getString(_creditPoolsKey) ?? '');

  CreditCosts get creditCosts =>
      CreditCosts.fromJsonString(_rc?.getString(_creditCostsKey) ?? '');
}
