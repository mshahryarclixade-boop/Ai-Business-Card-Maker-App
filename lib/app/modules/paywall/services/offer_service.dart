import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/services/remote_config_service.dart';
import '../controller/subscription_controller.dart';
import '../models/cro_config_model.dart';

/// The two discount offers of the CRO plan.
enum OfferType {
  /// Right after the user closed the paywall (once ever), over the paywall.
  firstYear('first_year'),

  /// On Home, on day 2-3, for a user who looked at the paywall and left.
  returning('returning');

  const OfferType(this.tag);
  final String tag;
}

/// Decides whether an offer may show, and remembers what was shown.
///
/// Rules (the plan):
///  * never to a subscribed user;
///  * only after the user has seen and left the paywall (the first-year offer
///    IS the reaction to leaving it);
///  * a SEPARATE discounted store product (`cro_offers.first_year_product_id`);
///    without one that the store really returns, no offer is shown - there is
///    no made-up price;
///  * the first-year offer once ever, the returning one once ever, and at most
///    `max_per_day` (1) offer dialogs per day;
///  * everything is remembered on the device.
class OfferService extends GetxService {
  OfferService({
    GetStorage? box,
    DateTime Function()? clock,
    bool Function()? isPro,
    CroOffers Function()? config,
    bool Function(String productId)? hasProduct,
  }) : _box = box ?? GetStorage(),
       _clock = clock ?? DateTime.now,
       _isPro = isPro ?? _defaultIsPro,
       _config = config ?? _defaultConfig,
       _hasProduct = hasProduct ?? _defaultHasProduct;

  static OfferService get to => Get.isRegistered<OfferService>()
      ? Get.find<OfferService>()
      : Get.put(OfferService(), permanent: true);

  static const storageKey = 'cro_offer_state';

  final GetStorage _box;
  final DateTime Function() _clock;
  final bool Function() _isPro;
  final CroOffers Function() _config;
  final bool Function(String) _hasProduct;

  static bool _defaultIsPro() =>
      Get.isRegistered<SubscriptionController>() &&
      Get.find<SubscriptionController>().isPro;

  static CroOffers _defaultConfig() => RemoteConfigService().croOffers;

  static bool _defaultHasProduct(String id) =>
      Get.isRegistered<SubscriptionController>() &&
      Get.find<SubscriptionController>().productFor(id) != null;

  @override
  void onInit() {
    super.onInit();
    // The day the offers' clock starts (day 1 = this day).
    final s = _state();
    if (s['install_day'] == null) {
      s['install_day'] = _dayKey(_clock());
      _save(s);
    }
  }

  // ---- State -------------------------------------------------------------------

  Map<String, dynamic> _state() {
    final raw = _box.read<String>(storageKey);
    if (raw == null) return {};
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {};
  }

  void _save(Map<String, dynamic> s) => _box.write(storageKey, jsonEncode(s));

  static String _dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// Times the user left the paywall without buying.
  int get paywallDismissals => (_state()['dismissed'] as int?) ?? 0;

  bool shown(OfferType t) => _state()['shown_${t.tag}'] == true;

  /// Offers shown today (the daily cap counts these).
  int get shownToday {
    final s = _state();
    return s['last_day'] == _dayKey(_clock()) ? (s['today_count'] as int? ?? 0) : 0;
  }

  /// Day number since install: the install day is day 1.
  int get dayNumber {
    final s = _state();
    final key = s['install_day'] as String?;
    if (key == null) return 1;
    final install = DateTime.parse(key);
    final today = DateTime(_clock().year, _clock().month, _clock().day);
    return today.difference(DateTime(install.year, install.month, install.day)).inDays + 1;
  }

  /// The paywall was closed without a purchase.
  void onPaywallDismissed() {
    if (_isPro()) return;
    final s = _state();
    s['dismissed'] = ((s['dismissed'] as int?) ?? 0) + 1;
    _save(s);
  }

  // ---- Eligibility ---------------------------------------------------------------

  /// The configured discounted product the store really returned (else null:
  /// no offer).
  String? get productId {
    final id = _config().firstYearProductId;
    return id.isNotEmpty && _hasProduct(id) ? id : null;
  }

  bool get _underDailyCap => shownToday < _config().maxPerDay;

  bool _common() =>
      !_isPro() && _config().enabled && productId != null && _underDailyCap;

  /// The first-year offer, for the moment the user closes the paywall.
  bool canShowFirstYear() => _common() && !shown(OfferType.firstYear);

  /// The returning-user offer, for Home.
  bool canShowReturning() {
    final c = _config();
    return _common() &&
        c.returningEnabled &&
        !shown(OfferType.returning) &&
        paywallDismissals > 0 &&
        dayNumber >= c.returningDayMin &&
        dayNumber <= c.returningDayMax;
  }

  /// Remembers that [t] was shown now (once ever; counts for today's cap).
  void markShown(OfferType t) {
    final s = _state();
    s['shown_${t.tag}'] = true;
    final today = _dayKey(_clock());
    s['today_count'] = s['last_day'] == today ? ((s['today_count'] as int?) ?? 0) + 1 : 1;
    s['last_day'] = today;
    _save(s);
  }
}
