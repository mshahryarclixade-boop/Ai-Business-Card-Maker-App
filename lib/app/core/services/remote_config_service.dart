import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../../modules/paywall/models/credit_config_model.dart';
import '../../modules/paywall/models/cro_config_model.dart';
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
        _scanOrientationToggleKey: false,
        // The CRO plan (limits, triggers, messages, experiment, offers).
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

  bool get onboardingEnabled => _rc?.getBool(_onboardingEnabledKey) ?? true;

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

  CroLimits get croLimits => _cro(CroKeys.limits, CroLimits.fromJsonString);
  CroTriggers get croTriggers =>
      _cro(CroKeys.triggers, CroTriggers.fromJsonString);
  CroMessages get croMessages =>
      _cro(CroKeys.messages, CroMessages.fromJsonString);
  CroExperiment get croExperiment =>
      _cro(CroKeys.experiment, CroExperiment.fromJsonString);
  CroOffers get croOffers => _cro(CroKeys.offers, CroOffers.fromJsonString);

  CreditPools get creditPools =>
      CreditPools.fromJsonString(_rc?.getString(_creditPoolsKey) ?? '');

  CreditCosts get creditCosts =>
      CreditCosts.fromJsonString(_rc?.getString(_creditCostsKey) ?? '');
}
