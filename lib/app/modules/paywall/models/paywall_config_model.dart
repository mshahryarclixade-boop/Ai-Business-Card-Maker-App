import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/services/remote_config_service.dart';
import '../controller/subscription_controller.dart';
import '../services/revenue_cat_service.dart';

import '../../../core/translations/tr_extension.dart';
import '../../../core/utils/localized_text.dart';

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
      // Under the plans screen's button, for the yearly plan with a real trial.
      'fine_print': '{days} days free, then {yearly_price}/year. Cancel anytime.',
    },
    // Screen 1 (trial pitch)
    'screen1': {
      'title_line1': 'Start creating',
      'title_line2': 'for free',
      'subtitle': 'Unlock everything with Pro',
      'features': [
        {'icon': 'scan', 'text': 'Unlimited card scans'},
        {'icon': 'ai', 'text': 'Design with AI, no limits'},
        {'icon': 'watermark', 'text': 'No watermark on exports'},
        {'icon': 'templates', 'text': 'All templates and QR styles'},
        {'icon': 'coach', 'text': 'AI Business Coach'},
      ],
      'plan_title': 'Yearly Pro',
      'save_badge': 'Save 64%',
      'price_note': 'Just \$2.50/month, billed annually',
    },
    // Screen 2 (plans)
    'screen2': {
      'title': 'Create and scan without limits',
      'subtitle': 'Get unlimited access to every feature',
      // The five feature points (CRO plan).
      'features': [
        'Unlimited card scans',
        'Design with AI, no limits',
        'No watermark on exports',
        'All templates and QR styles',
        'AI Business Coach',
      ],
      // Monthly selected (or no trial available): "Continue".
      'button_label': 'Continue',
      // Yearly selected and the store really offers the trial.
      'trial_button_label': 'Start Free Trial',
      'commitment_text': 'No commitment, cancel anytime',
    },
    // Headline per paywall source (a missing source uses its built-in one).
    'headlines': {
      'default': 'Create and scan without limits',
      'onboarding': 'Create and scan without limits',
      'scan_warning': 'Keep scanning with Pro',
      'scan_limit': 'Keep scanning with Pro',
      'ai_limit': 'Keep creating with AI',
      'pro_template': 'Unlock every template',
      'pro_qr': 'Unlock every QR style',
      'watermark': 'Export without the watermark',
      'clixa_limit': 'Keep talking to your AI coach',
      'crown': 'Create and scan without limits',
      'settings': 'Create and scan without limits',
      'career': 'Get found by the right people',
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
        'save_badge': 'Save 64%',
        'per_month_note': '{price}/month, billed yearly',
      },
    },
    'footer': {
      'restore': 'Restore Purchase',
      'terms': 'Terms of Use',
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
      } else if (v is String && o is Map) {
        // A text per language; the built-in text is the last fallback.
        out[k] = _LText(o, v);
      } else if ((v is bool && o is bool) ||
          // A text may also be a map of texts per language.
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
  /// A trial is shown only when Remote Config allows it AND the store really
  /// offers (and this user may have) the yearly free trial.
  bool get trialEnabled =>
      (RemoteConfigService().paywallOffers.trialEnabled ??
          _trial['enabled'] as bool) &&
      _storeTrial;

  /// The trial's real length from the store (the config's number only until
  /// the store answers).
  int get trialDays {
    final store = _storeTrialDays;
    return store > 0
        ? store
        : (RemoteConfigService().paywallOffers.trialDays ??
              (_trial['days'] as num).toInt());
  }

  static bool get _storeTrial =>
      Get.isRegistered<SubscriptionController>() &&
      Get.find<SubscriptionController>().yearlyTrialEligible.value;

  static int get _storeTrialDays => Get.isRegistered<SubscriptionController>()
      ? Get.find<SubscriptionController>().yearlyTrialDays.value
      : 0;

  /// Replaces `{days}` and `{yearly_price}` placeholders.
  String _fill(Object? s) => s
      .toString()
      .replaceAll('{days}', '$trialDays')
      .replaceAll('{yearly_price}', yearly.price);

  String get trialButtonLabel => _fill(
    _loc(
      trialEnabled ? _trial['button_label'] : _trial['no_trial_button_label'],
    ),
  );
  /// The plans screen's button for the monthly plan: "Continue".
  String get s2CtaLabel => _loc(_s2['button_label']);

  /// The plans screen's button: "Start Free Trial" for the yearly plan when
  /// the store really offers the trial to this user, else "Continue" (the
  /// trial is also explained in [s2FinePrint]).
  String s2CtaFor({required bool yearlySelected}) => yearlySelected
      ? _loc(_s2['trial_button_label'])
      : s2CtaLabel;

  /// The headline Remote Config set for [source] (`headlines.<source>`), as
  /// written; null when it is unset or still the English default (the caller
  /// then shows the translated built-in headline). [generic]: the source has
  /// no headline of its own, so `headlines.default` applies too.
  String? headlineFor(String source, {bool generic = false}) {
    final h = _m['headlines'] as Map;
    final d = defaultJson['headlines'] as Map;
    String? pick(String k) {
      final v = h[k];
      final r = v is _LText
          ? pickLocalized(v.texts)
          : v is Map
          ? pickLocalized(v)
          : (v is String ? v : null);
      return r != null && r.trim().isNotEmpty && r != d[k] ? r : null;
    }

    return pick(source) ?? (generic ? pick('default') : null);
  }

  /// Under the button: "3 days free, then $29.99/year. Cancel anytime." for
  /// the yearly plan when a trial is really available (store price and trial
  /// length), else the plain "No commitment, cancel anytime".
  String s2FinePrint({required bool yearlySelected}) => yearlySelected && trialEnabled
      ? _fill(_loc(_trial['fine_print']))
      : _loc(_s2['commitment_text']);

  String get trialBenefitText => _fill(_loc(_trial['benefit_text']));
  String get trialInfoLine1 => _fill(_loc(_trial['info_line_1']));
  String get trialInfoLine2 => _fill(_loc(_trial['info_line_2']));

  // --- Screen 1 ---
  String get s1TitleLine1 => _loc(_s1['title_line1']);
  String get s1TitleLine2 => _loc(_s1['title_line2']);
  String get s1Subtitle => _loc(_s1['subtitle']);
  String get s1PlanTitle => _loc(_s1['plan_title']);
  String get s1SaveBadge => _withSavePercent(_loc(_s1['save_badge']));
  String get s1PriceNote => _withPerMonth(_loc(_s1['price_note']));

  /// Each feature has an `icon` key (ai, scan, templates, qr, bg) and `text`.
  List<PaywallFeature> get s1Features {
    final list = _s1['features'];
    final out = <PaywallFeature>[];
    if (list is List) {
      final defaults = (defaultJson['screen1'] as Map)['features'] as List;
      for (var i = 0; i < list.length; i++) {
        final f = list[i];
        if (f is Map && (f['text'] is String || f['text'] is Map)) {
          out.add(
            PaywallFeature(
              f['icon']?.toString() ?? '',
              // A missing language falls back to the built-in text of the
              // same position.
              _loc(
                f['text'],
                fallback: i < defaults.length
                    ? (defaults[i] as Map)['text'] as String
                    : '',
              ),
            ),
          );
        }
      }
    }
    return out.isEmpty ? _defaultS1Features : out;
  }

  static List<PaywallFeature> get _defaultS1Features => [
    for (final f in (defaultJson['screen1'] as Map)['features'] as List)
      PaywallFeature(f['icon'] as String, _loc(f['text'])),
  ];

  // --- Screen 2 ---
  String get s2Title => _loc(_s2['title']);
  String get s2Subtitle => _loc(_s2['subtitle']);
  String get s2ButtonLabel => _loc(_s2['button_label']);
  String get s2CommitmentText => _loc(_s2['commitment_text']);

  List<String> get s2Features {
    final list = _s2['features'];
    final defaults = (defaultJson['screen2'] as Map)['features'] as List;
    final out = list is List
        ? [
            for (var i = 0; i < list.length; i++)
              if (list[i] is String || list[i] is Map)
                _loc(
                  list[i],
                  fallback: i < defaults.length ? defaults[i] as String : '',
                ),
          ]
        : <String>[];
    return out.isEmpty
        ? [
            for (final f in (defaultJson['screen2'] as Map)['features'] as List)
              _loc(f),
          ]
        : out;
  }

  // --- Plans ---
  PaywallPlan get monthly =>
      PaywallPlan(_plans['monthly'] as Map, product: _monthlyProduct);

  PaywallPlan get yearly {
    final p = _plans['yearly'] as Map;
    final m = _monthlyProduct;
    final y = _yearlyProduct;
    final perMonth = y == null
        ? _money(defaultYearlyPrice / 12, 'USD')
        : _money(y.price / 12, y.currencyCode);
    return PaywallPlan(
      p,
      product: y,
      perMonth: perMonth,
      savePercent: _savePercent,
      storeOriginalPrice: m == null
          ? null
          : '${_money(m.price * 12, m.currencyCode)}${_loc(p['period'])}',
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
    if (m == null || y == null || m.price <= 0) {
      // Store prices not loaded: the saving of the default prices (64%, not
      // the 70% the screen used to claim).
      return ((1 - defaultYearlyPrice / (defaultMonthlyPrice * 12)) * 100).round();
    }
    return ((1 - y.price / (m.price * 12)) * 100).round();
  }

  static const defaultMonthlyPrice = 6.99;
  static const defaultYearlyPrice = 29.99;

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
  String get restoreLabel => _loc(_footer['restore']);
  String get termsLabel => _loc(_footer['terms']);
  String get privacyLabel => _loc(_footer['privacy']);
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
    this.perMonth = '',
  });
  final Map _p;

  /// The store's product, once loaded — its price wins over the text.
  final StoreProduct? product;
  final int? savePercent;
  final String? storeOriginalPrice;

  /// Yearly price per month in the store's currency ("$2.50").
  final String perMonth;

  /// "$2.50/month, billed yearly" (empty for plans without the note).
  String get perMonthNote {
    final t = _loc((_p['per_month_note'] ?? ''));
    return t.isEmpty || perMonth.isEmpty ? '' : t.replaceAll('{price}', perMonth);
  }

  bool get visible => _p['visible'] as bool;
  String get title => _loc(_p['title']);
  String get price => product?.priceString ?? _p['price'] as String;
  String get period => _loc(_p['period']);
  String get description => _loc((_p['description'] ?? ''));
  String get badge => _loc((_p['badge'] ?? ''));
  String get originalPrice {
    final text = _loc((_p['original_price'] ?? ''));
    return text.isEmpty ? text : storeOriginalPrice ?? text;
  }

  String get saveBadge =>
      _withPercent(_loc((_p['save_badge'] ?? '')), savePercent);

  /// [text]'s first "70%" replaced by [percent], when known.
  /// Any script's digits (and the Arabic percent sign) are matched.
  static String _withPercent(String text, int? percent) => percent == null
      ? text
      : text.replaceFirst(
          RegExp(r'\p{Nd}+\s?[%٪]', unicode: true),
          '$percent%',
        );
}

/// The paywall's texts come from Remote Config, with English defaults. A text
/// that is still the English default is shown in the app language (the key
/// below); a text the remote config changed is shown as written there.
const Map<String, String> _defaultTextKeys = {
  'Start {days}-Day Free Trial': 'paywall_cfg_trial_button',
  'Continue': 'paywall_cfg_continue',
  'Start Free Trial': 'paywall_cfg_start_free_trial',
  '{days} days completely free, no charge today': 'paywall_cfg_trial_benefit',
  'No payment today, {yearly_price}/year after trial':
      'paywall_cfg_trial_info1',
  'Cancel anytime before trial ends': 'paywall_cfg_trial_info2',
  'Start creating': 'paywall_cfg_s1_title1',
  'for free': 'paywall_cfg_s1_title2',
  'Unlock everything with Pro': 'paywall_cfg_s1_subtitle',
  'Yearly Pro': 'paywall_cfg_yearly_pro',
  'Save 64%': 'paywall_cfg_save_badge',
  'Just \$2.50/month, billed annually': 'paywall_cfg_price_note',
  '{days} days free, then {yearly_price}/year. Cancel anytime.':
      'paywall_cfg_trial_fine_print',
  '{price}/month, billed yearly': 'paywall_cfg_billed_yearly',
  'Create and scan without limits': 'cro_msg_default_headline',
  'All templates and QR styles': 'paywall_cfg_s2_feat_all',
  'Get unlimited access to every feature': 'paywall_cfg_s2_subtitle',
  'Unlimited card scans': 'paywall_cfg_s2_feat_scan',
  'Design with AI, no limits': 'paywall_cfg_s2_feat_ai',
  'AI Business Coach': 'paywall_cfg_s2_feat_coach',
  'No watermark on exports': 'paywall_cfg_s2_feat_watermark',
  'No commitment, cancel anytime': 'paywall_cfg_commitment',
  'Monthly': 'paywall_cfg_monthly',
  '/month': 'paywall_cfg_per_month',
  'Full access to all Pro features': 'paywall_cfg_monthly_desc',
  'Yearly': 'paywall_cfg_yearly',
  'Most Popular': 'paywall_cfg_most_popular',
  '/year': 'paywall_cfg_per_year',
  '\$83.88/year': 'paywall_cfg_original_price',
  'Restore Purchase': 'paywall_cfg_restore',
  'Terms of Use': 'paywall_cfg_terms',
  'Privacy Policy': 'paywall_cfg_privacy',
};

/// A Remote Config text given per language, with the built-in text as the
/// fallback when the current language (and `default` / `en`) is missing.
class _LText {
  const _LText(this.texts, this.fallback);
  final Map texts;
  final String fallback;
}

String _loc(Object? v, {String fallback = ''}) {
  if (v is _LText) return _loc(pickLocalized(v.texts) ?? v.fallback);
  if (v is Map) {
    final picked = pickLocalized(v);
    return _loc(picked ?? fallback);
  }
  final s = v is String ? v : '';
  final key = _defaultTextKeys[s];
  return key == null ? s : key.tr;
}
