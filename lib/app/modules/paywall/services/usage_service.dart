import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/user_sync_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../controller/subscription_controller.dart';
import '../../email_signature/service/email_signature_store.dart';
import '../models/cro_config_model.dart';

/// What the free plan counts.
enum UsageFeature {
  scan('scan'),
  aiCard('ai_card'),
  clixaChat('clixa_chat'),
  careerBuild('career_build'),
  careerOptimize('career_optimize'),

  /// Email signatures CREATED (lifetime; deleting one does not give it back).
  emailSignature('email_signature');

  const UsageFeature(this.tag);

  /// Name in analytics and storage.
  final String tag;

  /// Resets by itself (a rolling 7-day window); all others are lifetime.
  bool get weekly => this == clixaChat;
}

/// The free plan's usage counters (CRO plan, Option A).
///
///  * Limits come from Remote Config (`cro_limits`), defaults = the plan.
///  * Lifetime counters never reset; Clixa chats reset 7 days after the first
///    chat of the window.
///  * Pro bypasses every limit and is not counted.
///  * [consume] with a `dedupeKey` spends one use per key, however many times
///    it is called (a retry or a rebuild never costs a second use).
///  * Only NEW uses are limited: nothing the user already made (cards,
///    contacts, drafts) is ever locked by this.
///
/// The counters are stored on the device (not per profile).
class UsageService extends GetxService {
  UsageService({
    GetStorage? box,
    DateTime Function()? clock,
    bool Function()? isPro,
    CroLimits Function()? limits,
  }) : _box = box ?? GetStorage(),
       _clock = clock ?? DateTime.now,
       _isPro = isPro ?? _defaultIsPro,
       _limits = limits ?? _defaultLimits;

  static UsageService get to => Get.isRegistered<UsageService>()
      ? Get.find<UsageService>()
      : Get.put(UsageService(), permanent: true);

  static const storageKey = 'cro_usage';
  static const _window = Duration(days: 7);
  static const _keepKeys = 50;

  final GetStorage _box;
  final DateTime Function() _clock;
  final bool Function() _isPro;
  final CroLimits Function() _limits;

  /// Bumped on every change: counters on screen watch it.
  final RxInt revision = 0.obs;

  static bool _defaultIsPro() =>
      Get.isRegistered<SubscriptionController>() &&
      Get.find<SubscriptionController>().isPro;

  static CroLimits _defaultLimits() => RemoteConfigService().croLimits;

  bool get isPro => _isPro();

  // ---- Reading ----------------------------------------------------------------

  Map<String, dynamic> _all() {
    final raw = _box.read<String>(storageKey);
    if (raw == null) return {};
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {};
  }

  Map<String, dynamic> _entry(UsageFeature f) {
    final e = _all()[f.tag];
    return e is Map<String, dynamic> ? e : {};
  }

  /// When this feature's current window began (null: none yet / lifetime).
  DateTime? _windowStart(Map<String, dynamic> e) {
    final ms = e['start'];
    return ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  bool _windowOver(UsageFeature f, Map<String, dynamic> e) {
    if (!f.weekly) return false;
    final start = _windowStart(e);
    return start != null && !_clock().isBefore(start.add(_window));
  }

  /// Free uses spent in the current window (all time for lifetime features).
  int used(UsageFeature f) {
    final e = _entry(f);
    if (_windowOver(f, e)) return 0;
    final u = e['used'];
    return u is int ? u : 0;
  }

  /// The free allowance for [f] (from Remote Config).
  int limitOf(UsageFeature f) {
    final l = _limits();
    return switch (f) {
      UsageFeature.scan => l.scanFree,
      UsageFeature.aiCard => l.aiCardFree,
      // Pro: Remote Config's Pro allowance (-1 = unlimited).
      UsageFeature.clixaChat =>
        isPro ? l.clixaChatsPerWeekPro : l.clixaChatsPerWeek,
      UsageFeature.careerBuild => l.careerBuildLifetime,
      UsageFeature.careerOptimize => l.careerOptimizeLifetime,
      UsageFeature.emailSignature => EmailSignatureStore.freeLimit,
    };
  }

  /// Pro users are counted only for a feature that has a Pro allowance
  /// (today Clixa chats, from `plan_limits`); -1 = unlimited = not counted.
  bool _proLimited(UsageFeature f) =>
      isPro && f == UsageFeature.clixaChat && limitOf(f) >= 0;

  /// True when Pro has no limit on [f].
  bool unlimitedForPro(UsageFeature f) => isPro && !_proLimited(f);

  int remaining(UsageFeature f) {
    final limit = limitOf(f);
    if (limit < 0) return 1 << 30;
    return (limit - used(f)).clamp(0, 1 << 30);
  }

  /// Pro (unlimited), or a use is left.
  bool canUse(UsageFeature f) => unlimitedForPro(f) || remaining(f) > 0;

  /// This was the last free use ("Last AI card generation" trigger) - i.e.
  /// none is left after the use just spent.
  bool isLastUsed(UsageFeature f) => !isPro && limitOf(f) > 0 && remaining(f) == 0;

  /// When a weekly feature's window ends (null if it has not started).
  DateTime? nextReset(UsageFeature f) {
    if (!f.weekly) return null;
    final e = _entry(f);
    final start = _windowStart(e);
    if (start == null || _windowOver(f, e)) return null;
    return start.add(_window);
  }

  // ---- Spending ---------------------------------------------------------------

  /// Spends one free use of [f]. Returns false (and spends nothing) when none
  /// is left; Pro always gets true and is not counted.
  ///
  /// [dedupeKey]: a use is counted once per key (e.g. the scanned image's
  /// path), so repeating the same action does not cost again.
  bool consume(UsageFeature f, {String? dedupeKey, String? source}) {
    if (unlimitedForPro(f)) {
      _report(f, dedupeKey);
      return true;
    }

    final all = _all();
    var e = Map<String, dynamic>.from(_entry(f));

    final keys = (e['keys'] as List?)?.whereType<String>().toList() ?? <String>[];
    if (dedupeKey != null && keys.contains(dedupeKey)) return true;

    if (_windowOver(f, e)) {
      e = {}; // a new window
    }
    final limit = limitOf(f);
    final spent = (e['used'] is int) ? e['used'] as int : 0;
    if (spent >= limit) {
      AnalyticsService.logLimitReached(
        feature: f.tag,
        limit: limit,
        source: source ?? f.tag,
      );
      return false;
    }

    e['used'] = spent + 1;
    // A weekly feature's first use opens a new week (the server counter restarts).
    int? newWindow;
    if (f.weekly && e['start'] == null) {
      newWindow = _clock().millisecondsSinceEpoch;
      e['start'] = newWindow;
    }
    if (dedupeKey != null) {
      keys.add(dedupeKey);
      if (keys.length > _keepKeys) keys.removeRange(0, keys.length - _keepKeys);
    }
    e['keys'] = keys;
    all[f.tag] = e;
    _box.write(storageKey, jsonEncode(all));
    revision.value++;

    _report(f, dedupeKey, newWindow);
    AnalyticsService.logUsageConsumed(
      feature: f.tag,
      used: spent + 1,
      limit: limit,
      source: source,
    );
    if (spent + 1 >= limit) {
      AnalyticsService.logLimitReached(
        feature: f.tag,
        limit: limit,
        source: source ?? f.tag,
      );
    }
    return true;
  }

  /// Tells the server about this use (the user's record `ai_usage/{user_id}`
  /// keeps the counts, so a reinstall does not reset the limits).
  void _report(UsageFeature f, String? dedupeKey, [int? windowStart]) =>
      UserSync.track(f.tag, eventId: dedupeKey, windowStart: windowStart);

  /// Brings the server's counters in (after a reinstall / on a new phone for a
  /// recovered subscriber): a counter only ever goes UP, never down. [remote]:
  /// `{feature: {used, windowStart?}}` as the server stores it.
  void mergeRemote(Map<String, dynamic> remote) {
    final all = _all();
    var changed = false;
    for (final f in UsageFeature.values) {
      final r = remote[f.tag];
      if (r is! Map) continue;
      final rUsed = r['used'] is num ? (r['used'] as num).toInt() : 0;
      if (rUsed <= 0) continue;
      var e = Map<String, dynamic>.from(_entry(f));
      if (f.weekly) {
        final rStart = r['windowStart'] is num ? (r['windowStart'] as num).toInt() : null;
        if (rStart == null) continue;
        final active = DateTime.fromMillisecondsSinceEpoch(rStart).add(_window).isAfter(_clock());
        if (!active) continue; // the server's window is over
        if (_windowOver(f, e)) e = {};
        final lUsed = e['used'] is int ? e['used'] as int : 0;
        if (rUsed <= lUsed) continue;
        e['used'] = rUsed;
        e['start'] = rStart;
      } else {
        final lUsed = e['used'] is int ? e['used'] as int : 0;
        if (rUsed <= lUsed) continue;
        e['used'] = rUsed;
      }
      all[f.tag] = e;
      changed = true;
    }
    if (!changed) return;
    _box.write(storageKey, jsonEncode(all));
    revision.value++;
  }

  /// Forgets every counter (tests, support).
  Future<void> resetAll() async {
    await _box.remove(storageKey);
    revision.value++;
  }
}

/// For code that may run before / without the service (stores, tests).
abstract final class UsageHelper {
  /// Counts one free use of [f] once ever per [key]; never throws.
  static void count(UsageFeature f, String key, String source) {
    try {
      UsageService.to.consume(f, dedupeKey: key, source: source);
    } catch (_) {}
  }
}
