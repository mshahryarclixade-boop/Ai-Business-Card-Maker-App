import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../controller/subscription_controller.dart';
import '../services/revenue_cat_service.dart';

import '../../../core/translations/tr_extension.dart';

/// Paywall copy and display settings, delivered as one JSON parameter
/// (`paywall_config`) in Firebase Remote Config.
///
/// Parsing is tolerant: the remote JSON is merged over [defaultJson], so a
/// missing, empty or malformed value (or a partial override) always yields a
/// complete config identical to the paywall as it shipped. Prices come from
/// the store once its products load (the user's own currency, matching the
/// purchase sheet); the prices here are only shown until then.
class PaywallConfig {
  PaywallConfig._(this._m);

  final Map<String, dynamic> _m;

  /// Fallback used before the first fetch, offline, or on bad JSON.
  static const Map<String, dynamic> defaultJson = {
    // Display settings
    'enabled': true,
    'show_on_launch': true,
    'show_close_button': true,
    // false = the first screen's button buys the yearly plan directly
    // (the plans screen, PaywallView2, is not opened).
    'show_plans_screen': false,
    // Trial
    'trial': {
      'enabled': true,
      'days': 3,
      'button_label': 'Start {days}-Day Free Trial',
      'no_trial_button_label': 'Continue',
      'benefit_text': '{days} days completely free, no charge today',
      'info_line_1': 'No payment today, {yearly_price}/year after trial',
      'info_line_2': 'Cancel anytime before trial ends',
    },
    // Screen 1 (trial pitch)
    'screen1': {
      'title_line1': 'Start creating',
      'title_line2': 'for free',
      'subtitle': 'Unlock everything with Pro',
      'features': [
        {'icon': 'ai', 'text': 'Unlimited AI Card Generation'},
        {'icon': 'scan', 'text': 'Scan Unlimited Cards'},
        {'icon': 'templates', 'text': '50+ Premium Templates'},
        {'icon': 'qr', 'text': 'Scan any QR Code'},
        {'icon': 'bg', 'text': 'Remove Background'},
      ],
      'plan_title': 'Yearly Pro',
      'save_badge': 'Save 70%',
      'price_note': 'Just \$2.49/month, billed annually',
    },
    // Screen 2 (plans)
    'screen2': {
      'title': 'Unlock Pro & keep creating',
      'subtitle': 'Get unlimited access to every feature',
      'features': [
        'Unlimited AI Card',
        'Unlimited Scan',
        '50+ Templates',
        'No watermark',
        'QR Generator',
        'BG Remover',
      ],
      'button_label': 'Continue',
      'commitment_text': 'No commitment, cancel anytime',
    },
    // Plans (display text; shared by both screens)
    'plans': {
      'monthly': {
        'visible': true,
        'title': 'Monthly',
        'price': '\$6.99',
        'period': '/month',
        'description': 'Full access to all Pro features',
      },
      'yearly': {
        'visible': true,
        'title': 'Yearly',
        'badge': 'Most Popular',
        'price': '\$29.99',
        'period': '/year',
        'original_price': '\$83.88/year',
        'save_badge': 'Save 70%',
      },
    },
    'footer': {
      'restore': 'Restore Purchase',
      'terms': 'Term Of Use',
      'privacy': 'Privacy Policy',
    },
  };

  static PaywallConfig get defaults => PaywallConfig._(_merge(defaultJson, {}));

  /// Parses a Remote Config string; any problem falls back to [defaults].
  factory PaywallConfig.fromJsonString(String raw) {
    if (raw.trim().isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return PaywallConfig._(_merge(defaultJson, decoded));
      }
    } catch (e) {
      log(
        'Invalid paywall_config JSON, using defaults: $e',
        name: 'PaywallConfig',
      );
    }
    return defaults;
  }

  /// Deep-merges [over] onto [base]; maps merge, everything else replaces.
  /// A value whose type differs from the default is ignored.
  static Map<String, dynamic> _merge(Map base, Map over) {
    final out = <String, dynamic>{};
    base.forEach((k, v) {
      final o = over[k];
      if (v is Map) {
        out[k] = _merge(v, o is Map ? o : const {});
      } else if ((v is bool && o is bool) ||
          (v is String && o is String) ||
          (v is num && o is num) ||
          (v is List && o is List)) {
        out[k] = o;
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  Map get _trial => _m['trial'] as Map;
  Map get _s1 => _m['screen1'] as Map;
  Map get _s2 => _m['screen2'] as Map;
  Map get _plans => _m['plans'] as Map;
  Map get _footer => _m['footer'] as Map;

  // --- Display settings ---
  bool get enabled => _m['enabled'] as bool;
  bool get showOnLaunch => _m['show_on_launch'] as bool;
  bool get showCloseButton => _m['show_close_button'] as bool;
  bool get showPlansScreen => _m['show_plans_screen'] as bool;

  // --- Trial ---
  bool get trialEnabled => _trial['enabled'] as bool;
  int get trialDays => (_trial['days'] as num).toInt();

  /// Replaces `{days}` and `{yearly_price}` placeholders.
  String _fill(Object? s) => s
      .toString()
      .replaceAll('{days}', '$trialDays')
      .replaceAll('{yearly_price}', yearly.price);

  String get trialButtonLabel => _fill(
    _loc(
      (trialEnabled ? _trial['button_label'] : _trial['no_trial_button_label'])
          as String,
    ),
  );
  String get trialBenefitText => _fill(_loc(_trial['benefit_text'] as String));
  String get trialInfoLine1 => _fill(_loc(_trial['info_line_1'] as String));
  String get trialInfoLine2 => _fill(_loc(_trial['info_line_2'] as String));

  // --- Screen 1 ---
  String get s1TitleLine1 => _loc(_s1['title_line1'] as String);
  String get s1TitleLine2 => _loc(_s1['title_line2'] as String);
  String get s1Subtitle => _loc(_s1['subtitle'] as String);
  String get s1PlanTitle => _loc(_s1['plan_title'] as String);
  String get s1SaveBadge => _withSavePercent(_loc(_s1['save_badge'] as String));
  String get s1PriceNote => _withPerMonth(_loc(_s1['price_note'] as String));

  /// Each feature has an `icon` key (ai, scan, templates, qr, bg) and `text`.
  List<PaywallFeature> get s1Features {
    final list = _s1['features'];
    final out = <PaywallFeature>[];
    if (list is List) {
      for (final f in list) {
        if (f is Map && f['text'] is String) {
          out.add(
            PaywallFeature(
              f['icon']?.toString() ?? '',
              _loc(f['text'] as String),
            ),
          );
        }
      }
    }
    return out.isEmpty ? _defaultS1Features : out;
  }

  static List<PaywallFeature> get _defaultS1Features => [
    for (final f in (defaultJson['screen1'] as Map)['features'] as List)
      PaywallFeature(f['icon'] as String, _loc(f['text'] as String)),
  ];

  // --- Screen 2 ---
  String get s2Title => _loc(_s2['title'] as String);
  String get s2Subtitle => _loc(_s2['subtitle'] as String);
  String get s2ButtonLabel => _loc(_s2['button_label'] as String);
  String get s2CommitmentText => _loc(_s2['commitment_text'] as String);

  List<String> get s2Features {
    final list = _s2['features'];
    final out = list is List
        ? list.whereType<String>().map(_loc).toList()
        : <String>[];
    return out.isEmpty
        ? [
            for (final f in (defaultJson['screen2'] as Map)['features'] as List)
              _loc(f as String),
          ]
        : out;
  }

  // --- Plans ---
  PaywallPlan get monthly =>
      PaywallPlan(_plans['monthly'] as Map, product: _monthlyProduct);

  PaywallPlan get yearly {
    final p = _plans['yearly'] as Map;
    final m = _monthlyProduct;
    return PaywallPlan(
      p,
      product: _yearlyProduct,
      savePercent: _savePercent,
      storeOriginalPrice: m == null
          ? null
          : '${_money(m.price * 12, m.currencyCode)}${_loc(p['period'] as String)}',
    );
  }

  // --- Store prices ---
  static StoreProduct? _product(String id) =>
      Get.isRegistered<SubscriptionController>()
      ? Get.find<SubscriptionController>().productFor(id)
      : null;

  StoreProduct? get _monthlyProduct =>
      _product(RevenueCatHelper.monthlyProductId);
  StoreProduct? get _yearlyProduct =>
      _product(RevenueCatHelper.yearlyProductId);

  /// Yearly's saving over twelve months of monthly; null until both store
  /// prices are known.
  int? get _savePercent {
    final m = _monthlyProduct, y = _yearlyProduct;
    if (m == null || y == null || m.price <= 0) return null;
    return ((1 - y.price / (m.price * 12)) * 100).round();
  }

  static String _money(double value, String currencyCode) =>
      NumberFormat.simpleCurrency(name: currencyCode).format(value);

  /// "Save 70%" with the saving the store prices really give.
  String _withSavePercent(String text) =>
      PaywallPlan._withPercent(text, _savePercent);

  /// "Just $2.49/month, billed annually" with yearly's real price per
  /// month in the store's currency.
  String _withPerMonth(String text) {
    final y = _yearlyProduct;
    if (y == null) return text;
    return text.replaceFirst(
      RegExp(r'[$€£¥₹]\s?\d+(?:[.,]\d+)?'),
      _money(y.price / 12, y.currencyCode),
    );
  }

  // --- Footer ---
  String get restoreLabel => _loc(_footer['restore'] as String);
  String get termsLabel => _loc(_footer['terms'] as String);
  String get privacyLabel => _loc(_footer['privacy'] as String);
}

class PaywallFeature {
  const PaywallFeature(this.icon, this.text);
  final String icon;
  final String text;
}

class PaywallPlan {
  const PaywallPlan(
    this._p, {
    this.product,
    this.savePercent,
    this.storeOriginalPrice,
  });
  final Map _p;

  /// The store's product, once loaded — its price wins over the text.
  final StoreProduct? product;
  final int? savePercent;
  final String? storeOriginalPrice;

  bool get visible => _p['visible'] as bool;
  String get title => _loc(_p['title'] as String);
  String get price => product?.priceString ?? _p['price'] as String;
  String get period => _loc(_p['period'] as String);
  String get description => _loc((_p['description'] ?? '') as String);
  String get badge => _loc((_p['badge'] ?? '') as String);
  String get originalPrice {
    final text = _loc((_p['original_price'] ?? '') as String);
    return text.isEmpty ? text : storeOriginalPrice ?? text;
  }

  String get saveBadge =>
      _withPercent(_loc((_p['save_badge'] ?? '') as String), savePercent);

  /// [text]'s first "70%" replaced by [percent], when known.
  static String _withPercent(String text, int? percent) => percent == null
      ? text
      : text.replaceFirst(RegExp(r'\d+\s?%'), '$percent%');
}

/// The paywall's texts come from Remote Config, with English defaults. A text
/// that is still the English default is shown in the app language (the key
/// below); a text the remote config changed is shown as written there.
const Map<String, String> _defaultTextKeys = {
  'Start {days}-Day Free Trial': 'paywall_cfg_trial_button',
  'Continue': 'paywall_cfg_continue',
  '{days} days completely free, no charge today': 'paywall_cfg_trial_benefit',
  'No payment today, {yearly_price}/year after trial':
      'paywall_cfg_trial_info1',
  'Cancel anytime before trial ends': 'paywall_cfg_trial_info2',
  'Start creating': 'paywall_cfg_s1_title1',
  'for free': 'paywall_cfg_s1_title2',
  'Unlock everything with Pro': 'paywall_cfg_s1_subtitle',
  'Unlimited AI Card Generation': 'paywall_cfg_feat_ai',
  'Scan Unlimited Cards': 'paywall_cfg_feat_scan',
  '50+ Premium Templates': 'paywall_cfg_feat_templates',
  'Scan any QR Code': 'paywall_cfg_feat_qr',
  'Remove Background': 'paywall_cfg_feat_bg',
  'Yearly Pro': 'paywall_cfg_yearly_pro',
  'Save 70%': 'paywall_cfg_save_badge',
  'Just \$2.49/month, billed annually': 'paywall_cfg_price_note',
  'Unlock Pro & keep creating': 'paywall_cfg_s2_title',
  'Get unlimited access to every feature': 'paywall_cfg_s2_subtitle',
  'Unlimited AI Card': 'paywall_cfg_s2_feat_ai',
  'Unlimited Scan': 'paywall_cfg_s2_feat_scan',
  '50+ Templates': 'paywall_cfg_s2_feat_templates',
  'No watermark': 'paywall_cfg_s2_feat_watermark',
  'QR Generator': 'paywall_cfg_s2_feat_qr',
  'BG Remover': 'paywall_cfg_s2_feat_bg',
  'No commitment, cancel anytime': 'paywall_cfg_commitment',
  'Monthly': 'paywall_cfg_monthly',
  '/month': 'paywall_cfg_per_month',
  'Full access to all Pro features': 'paywall_cfg_monthly_desc',
  'Yearly': 'paywall_cfg_yearly',
  'Most Popular': 'paywall_cfg_most_popular',
  '/year': 'paywall_cfg_per_year',
  '\$83.88/year': 'paywall_cfg_original_price',
  'Restore Purchase': 'paywall_cfg_restore',
  'Term Of Use': 'paywall_cfg_terms',
  'Privacy Policy': 'paywall_cfg_privacy',
};

String _loc(String s) {
  final key = _defaultTextKeys[s];
  return key == null ? s : key.tr;
}
