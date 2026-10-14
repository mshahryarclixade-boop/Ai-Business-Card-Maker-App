import 'dart:convert';
import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../modules/paywall/models/credit_config_model.dart';
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

  static const _paywallConfigKey = 'paywall_config';

  FirebaseRemoteConfig? _rc;

  // Parsed-config cache: re-parse only when the raw JSON changes.
  String? _paywallRaw;
  PaywallConfig? _paywallConfig;

  Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await rc.setDefaults({
        _creditsEnabledKey: false,
        _creditPoolsKey: '',
        _creditCostsKey: '',
        _paywallConfigKey: jsonEncode(PaywallConfig.defaultJson),
      });
      _rc = rc;
      await rc.fetchAndActivate();
    } catch (e) {
      log(
        'Remote Config init failed, using defaults: $e',
        name: 'RemoteConfigService',
      );
    }
  }

  /// Master switch: while false, the credit gate lets everything through.
  bool get creditsEnabled => _rc?.getBool(_creditsEnabledKey) ?? false;

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

  CreditPools get creditPools =>
      CreditPools.fromJsonString(_rc?.getString(_creditPoolsKey) ?? '');

  CreditCosts get creditCosts =>
      CreditCosts.fromJsonString(_rc?.getString(_creditCostsKey) ?? '');
}
