import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../modules/paywall/controller/subscription_controller.dart';
import '../../modules/paywall/services/revenue_cat_service.dart';
import '../../modules/paywall/services/usage_service.dart';
import 'device_identity.dart';
import 'device_usage_store.dart';

/// This device's usage document `devices/{deviceId}` - read and written by the
/// app itself (no Cloud Functions, no login). The device id is the real device
/// id, so a reinstall opens the same document and the counters continue.
///
///  * [sync] / [refresh]: at start, on resume, after a purchase / restore and
///    before a limited action: reads the document (creates it as free with
///    every counter at 0 when it does not exist), writes platform / app
///    version / plan / expiry, and brings the counters into [UsageService].
///    Offline or slow: the last known counts stay in use.
///  * [track]: one use of a feature -> `FieldValue.increment(1)` on its counter
///    (the Firestore SDK keeps the write and sends it when the phone is back
///    online).
///
/// Pro still comes from RevenueCat; the plan stored here is a record only.
/// Never throws and never blocks a feature.
abstract final class UserSync {
  /// The storage. Swappable in tests.
  static DeviceStore store = FirestoreDeviceStore();

  /// Off in tests that do not set up Firebase.
  static bool Function() available = () => Firebase.apps.isNotEmpty;

  /// Every counter of a document (same names as in `firestore.rules`).
  static const features = [
    'scan',
    'ai_card',
    'clixa_chat',
    'career_build',
    'career_optimize',
    'email_signature',
    'template',
    'qr',
    'contacts',
    'bg_remover',
    'expert_panel',
  ];

  static AppLifecycleListener? _lifecycle;
  static DateTime? _lastSync;
  static Future<void>? _inFlight;
  static final _ready = <String>{}; // ids known to exist this session

  // ---- reading / creating ----------------------------------------------------

  /// Reads the document before a limited action (3 s at most).
  static Future<void> refresh() async {
    if (!available()) return;
    try {
      await sync(force: true).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  static Future<void> sync({bool force = false}) {
    if (!available()) return Future.value();
    final running = _inFlight;
    if (running != null) return running;
    final last = _lastSync;
    if (!force && last != null && DateTime.now().difference(last) < const Duration(seconds: 30)) {
      return Future.value();
    }
    return _inFlight = _doSync().whenComplete(() => _inFlight = null);
  }

  static Future<void> _doSync() async {
    try {
      final id = await DeviceIdentity.userIdOrNull();
      if (id == null) return;
      final r = await store.read(id);
      var data = r.data;
      if (data == null) {
        if (r.fromCache) return; // offline: never create from a cache miss
        await store.create(id, await _newDocument(id));
        data = {'counters': {for (final f in features) f: {'used': 0}}};
      }
      _ready.add(id);
      _lastSync = DateTime.now();
      final counters = data['counters'];
      if (counters is Map && Get.isRegistered<UsageService>()) {
        UsageService.to.mergeRemote(Map<String, dynamic>.from(counters));
        await _catchUp(id, Map<String, dynamic>.from(counters));
      }
      await store.update(id, await _meta());
    } catch (_) {
      // already written to the debug log by the store
    }
  }

  /// Uses that were counted on the phone while Firestore was out of reach (or
  /// before this document existed) are sent now, one `+1` per write (the rules
  /// allow no more). Lifetime counters only, a few at most.
  static Future<void> _catchUp(String id, Map<String, dynamic> remote) async {
    if (!Get.isRegistered<UsageService>()) return;
    final usage = UsageService.to;
    for (final f in UsageFeature.values) {
      if (f.weekly) continue;
      final server = (remote[f.tag] is Map && remote[f.tag]['used'] is num)
          ? (remote[f.tag]['used'] as num).toInt()
          : 0;
      final missing = (usage.used(f) - server).clamp(0, 10);
      for (var i = 0; i < missing; i++) {
        await store.update(id, {'counters.${f.tag}.used': FieldValue.increment(1)});
      }
    }
  }

  static Future<Map<String, dynamic>> _newDocument(String id) async => {
    'deviceId': id,
    'platform': Platform.isIOS ? 'ios' : 'android',
    'appVersion': await _version(),
    'createdAt': FieldValue.serverTimestamp(),
    'lastSeenAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'plan': {'tier': 'free', 'isPro': false, 'expiresAt': null},
    'counters': {for (final f in features) f: {'used': 0}},
  };

  static Future<String> _version() async {
    try {
      final p = await PackageInfo.fromPlatform();
      return '${p.version}+${p.buildNumber}';
    } catch (_) {
      return '';
    }
  }

  // ---- plan ------------------------------------------------------------------

  /// platform / version / plan / expiry. The plan is what RevenueCat says
  /// (monthly and weekly count as monthly; the yearly trial as yearly).
  static Future<Map<String, dynamic>> _meta() async {
    var tier = 'free';
    var pro = Get.isRegistered<SubscriptionController>() && Get.find<SubscriptionController>().isPro;
    String? productId;
    DateTime? expires;
    try {
      final info = await Purchases.getCustomerInfo();
      final ent = info.entitlements.all[RevenueCatHelper.entitlementIdentifier];
      if (ent != null && ent.isActive) {
        pro = true;
        productId = ent.productIdentifier;
        expires = DateTime.tryParse(ent.expirationDate ?? '');
      }
    } catch (_) {}
    if (pro) tier = (productId ?? '').toLowerCase().contains('year') ? 'yearly' : 'monthly';
    return {
      'plan': {
        'tier': tier,
        'isPro': pro,
        'expiresAt': pro ? expires : null,
        'productId': ?productId,
      },
      'platform': Platform.isIOS ? 'ios' : 'android',
      'appVersion': await _version(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ---- counting ----------------------------------------------------------------

  /// One use of [feature]. [windowStart]: a weekly feature opens a NEW week
  /// (the counter restarts at 1). [eventId] / [detail] are not stored (counts
  /// only; a repeat is already ignored on the phone).
  static void track(String feature, {String? eventId, String? detail, int? windowStart}) {
    if (!available() || !features.contains(feature)) return;
    unawaited(_track(feature, windowStart));
  }

  static Future<void> _track(String feature, int? windowStart) async {
    try {
      final id = await DeviceIdentity.userIdOrNull();
      if (id == null) return;
      if (!_ready.contains(id)) {
        await sync(force: true).timeout(const Duration(seconds: 5), onTimeout: () {});
        if (!_ready.contains(id)) return; // offline before the first sync: counted on the phone, sent by the catch-up
      }
      await store.update(
        id,
        windowStart != null
            ? {'counters.$feature': {'used': 1, 'windowStart': windowStart}}
            : {'counters.$feature.used': FieldValue.increment(1)},
      );
    } catch (_) {
      // logged by the store
    }
  }

  /// At app start: syncs now, when the app comes back, and whenever Pro starts
  /// or ends (a purchase or a restore writes the plan and expiry).
  static void start() {
    if (!available()) return;
    unawaited(sync(force: true));
    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(sync()));
    if (Get.isRegistered<SubscriptionController>()) {
      ever<bool>(
        Get.find<SubscriptionController>().isUserPro,
        (_) => unawaited(sync(force: true)),
      );
    }
  }

  /// For tests.
  static void resetForTest() {
    _lastSync = null;
    _inFlight = null;
    _ready.clear();
  }
}
