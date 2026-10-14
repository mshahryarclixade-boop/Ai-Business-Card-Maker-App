import 'dart:async';
import 'dart:developer';
import 'dart:math' show max;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/remote_config_service.dart';
import '../models/credit_config_model.dart';

/// Local (SharedPreferences-backed) cache of the user's shared credit
/// balance — a single pool spent by every generation. Firestore
/// (`users/{deviceUdid}`) is the actual source of truth: every mutation
/// writes through to it in a transaction, and [initUser] hydrates the local
/// cache from it on first run after an install, so uninstalling and
/// reinstalling (which wipes SharedPreferences but not the Keychain/
/// Keystore-backed UDID [FlutterUdid] reads) doesn't reset the balance.
class UserCreditsManager {
  static const String proStatusKey = 'is_pro';
  static const String planTierKey = 'plan_tier';
  static const String balanceKey = 'credit_balance';
  static const String initializedKey = 'initialized';
  static const String _deviceUdidKey = 'device_udid';

  /// Set whenever a write to Firestore fails and falls back to a
  /// local-only update. While true, the local cache holds the most recent
  /// truth, so [_refreshCacheFromRemote] must not pull from Firestore until
  /// the pending write has been retried and confirmed to land.
  static const String _pendingSyncKey = 'credit_pending_sync';

  /// The free-tier balance a device had when it went Pro — restored by
  /// [downgradeToFree] when the subscription later lapses, so a
  /// subscribe-then-cancel cycle can't re-earn a fresh free pool.
  static const String _preProBalanceKey = 'pre_pro_balance';

  /// The billing-period anchor (entitlement `latestPurchaseDate`) that the
  /// last Pro credit top-up was granted for. Mirrored to Firestore so a
  /// reinstall doesn't look like "never assigned" and re-grant a full pool.
  static const String lastCreditAssignedKey = 'last_credit_assigned_date';

  /// Set when [initUser] can't confirm from Firestore whether this device
  /// already has a record and falls back to granting a free pool as a
  /// guess. Distinct from [_pendingSyncKey]: this guess must never be
  /// pushed over a real existing balance — [_refreshCacheFromRemote]
  /// retries the exists-or-not check first.
  static const String _pendingInitKey = 'credit_pending_init';

  static const String _usersCollection = 'users';

  /// Swappable for a fake in tests.
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Swappable for a synthetic [CreditPools] in tests.
  static CreditPools Function() creditPoolsProvider = () =>
      RemoteConfigService().creditPools;

  Future<String> _deviceUdid() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_deviceUdidKey);
    if (cached != null) return cached;

    final udid = await FlutterUdid.consistentUdid;
    await prefs.setString(_deviceUdidKey, udid);
    return udid;
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String udid) =>
      firestore.collection(_usersCollection).doc(udid);

  /// Copies a Firestore user document into the local cache.
  Future<void> _applyRemote(
    SharedPreferences prefs,
    Map<String, dynamic> data, {
    bool defaults = false,
  }) async {
    final balance = (data[balanceKey] as num?)?.toInt();
    final isPro = data[proStatusKey] as bool?;
    final planTier = data[planTierKey] as String?;
    final preProBalance = (data[_preProBalanceKey] as num?)?.toInt();
    final lastCreditAssigned = data[lastCreditAssignedKey] as String?;

    if (balance != null || defaults) {
      await prefs.setInt(balanceKey, balance ?? 0);
    }
    if (isPro != null || defaults) {
      await prefs.setBool(proStatusKey, isPro ?? false);
    }
    if (planTier != null || defaults) {
      await prefs.setString(planTierKey, planTier ?? 'free');
    }
    if (preProBalance != null || defaults) {
      await prefs.setInt(_preProBalanceKey, preProBalance ?? 0);
    }
    if (lastCreditAssigned != null) {
      await prefs.setString(lastCreditAssignedKey, lastCreditAssigned);
    }
  }

  /// Re-reads Firestore (the source of truth) and refreshes the local cache
  /// before every [getBalance]/[isPro] call. If a local write is still
  /// pending, it is pushed up first rather than overwritten by a stale
  /// remote value. A Firestore outage just leaves the local cache as the
  /// answer.
  Future<void> _refreshCacheFromRemote() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_pendingInitKey) ?? false) {
      await _resolvePendingInit(prefs);
      return;
    }

    if (prefs.getBool(_pendingSyncKey) ?? false) {
      await _retryPendingSync(prefs);
      return;
    }

    final udid = await _deviceUdid();
    try {
      final snap = await _userDoc(udid).get();
      if (!snap.exists) return;
      await _applyRemote(prefs, snap.data()!);
    } catch (e) {
      log(
        'Firestore read failed, using local cache: $e',
        name: 'UserCreditsManager',
      );
    }
  }

  /// Retries the exists-or-not check [initUser] couldn't complete earlier.
  /// If a record already existed the guess is discarded and the real state
  /// restored; if there really is none, the guessed grant is written up.
  Future<void> _resolvePendingInit(SharedPreferences prefs) async {
    final udid = await _deviceUdid();
    try {
      final snap = await _userDoc(udid).get();
      if (snap.exists) {
        await _applyRemote(prefs, snap.data()!, defaults: true);
        // The offline guess is known to be wrong — abandon it.
        await prefs.setBool(_pendingSyncKey, false);
        log(
          'resolved pending init — restored existing balance for $udid',
          name: 'UserCreditsManager',
        );
      } else {
        await _userDoc(udid).set({
          proStatusKey: prefs.getBool(proStatusKey) ?? false,
          planTierKey: prefs.getString(planTierKey) ?? 'free',
          balanceKey: prefs.getInt(balanceKey) ?? 0,
          _preProBalanceKey: prefs.getInt(_preProBalanceKey) ?? 0,
        });
        log(
          'resolved pending init — confirmed new user, recorded guessed grant',
          name: 'UserCreditsManager',
        );
      }
      await prefs.setBool(_pendingInitKey, false);
    } catch (e) {
      log(
        'pending init still unresolved, staying on local guess: $e',
        name: 'UserCreditsManager',
      );
    }
  }

  /// Pushes the local cache's state up to Firestore and clears
  /// [_pendingSyncKey] once that succeeds.
  Future<void> _retryPendingSync(SharedPreferences prefs) async {
    final udid = await _deviceUdid();
    try {
      final lastCreditAssigned = prefs.getString(lastCreditAssignedKey);
      await _userDoc(udid).set({
        balanceKey: prefs.getInt(balanceKey) ?? 0,
        proStatusKey: prefs.getBool(proStatusKey) ?? false,
        planTierKey: prefs.getString(planTierKey) ?? 'free',
        _preProBalanceKey: prefs.getInt(_preProBalanceKey) ?? 0,
        lastCreditAssignedKey: ?lastCreditAssigned,
      }, SetOptions(merge: true));
      await prefs.setBool(_pendingSyncKey, false);
      log(
        'pending local balance synced to Firestore',
        name: 'UserCreditsManager',
      );
    } catch (e) {
      log(
        'retry sync still failing, staying local-authoritative: $e',
        name: 'UserCreditsManager',
      );
    }
  }

  Future<int> getBalance() async {
    await _refreshCacheFromRemote();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(balanceKey) ?? 0;
  }

  Future<bool> isPro() async {
    await _refreshCacheFromRemote();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(proStatusKey) ?? false;
  }

  /// The tier on record — a Pro plan's tier or `free`.
  Future<String?> getPlanTier() async {
    await _refreshCacheFromRemote();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(planTierKey);
  }

  /// The billing-period anchor of the last Pro credit top-up, mirrored
  /// from/to Firestore — see [lastCreditAssignedKey].
  Future<String?> getLastCreditAssignedDate() async {
    await _refreshCacheFromRemote();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastCreditAssignedKey);
  }

  Future<void> setLastCreditAssignedDate(String iso) async {
    final prefs = await SharedPreferences.getInstance();
    final udid = await _deviceUdid();
    await prefs.setString(lastCreditAssignedKey, iso);
    try {
      await _userDoc(
        udid,
      ).set({lastCreditAssignedKey: iso}, SetOptions(merge: true));
    } catch (e) {
      log(
        'Firestore lastCreditAssignedDate write failed, local cache still updated: $e',
        name: 'UserCreditsManager',
      );
      await prefs.setBool(_pendingSyncKey, true);
    }
  }

  /// The balance as saved on this device, without waiting on Firestore —
  /// what the credit gate decides on. Null when it isn't known on this
  /// device yet, so a setup failure is never mistaken for "out of credits".
  Future<int?> knownBalance() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(initializedKey) ?? false)) {
      try {
        // Bounded: offline, Firestore can take many seconds to give up.
        await initUser().timeout(const Duration(seconds: 3));
      } catch (e) {
        log('initUser retry failed: $e', name: 'UserCreditsManager');
      }
    }
    unawaited(
      _refreshCacheFromRemote().catchError(
        (Object e) => log('background refresh: $e', name: 'UserCreditsManager'),
      ),
    );
    return prefs.getInt(balanceKey);
  }

  /// The Pro flag as saved on this device, without waiting on Firestore.
  Future<bool> cachedIsPro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(proStatusKey) ?? false;
  }

  /// Deducts [cost] credits, never below 0 (-1 means unlimited).
  Future<int> deduct(int cost) async {
    if (cost <= 0) return getBalance();
    return _mutateBalance(
      (current) => current == -1 ? current : max(0, current - cost),
    );
  }

  /// Gives back [cost] credits previously spent by [deduct]. No-op when
  /// unlimited (-1).
  Future<int> refund(int cost) async {
    if (cost <= 0) return getBalance();
    return _mutateBalance(
      (current) => current == -1 ? current : current + cost,
    );
  }

  /// Runs [update] against the balance Firestore currently holds inside a
  /// transaction, then mirrors the result locally. Falls back to a
  /// local-only update if Firestore is unreachable.
  Future<int> _mutateBalance(int Function(int current) update) async {
    final prefs = await SharedPreferences.getInstance();
    final udid = await _deviceUdid();

    try {
      final updated = await firestore.runTransaction<int>((tx) async {
        final doc = _userDoc(udid);
        final snap = await tx.get(doc);
        final data = snap.data() ?? const <String, dynamic>{};
        final current = (data[balanceKey] as num?)?.toInt() ?? 0;
        final next = update(current);
        // Writes back the whole snapshot with only the balance changed, so
        // a deduct/refund can never affect Pro status.
        tx.set(doc, {...data, balanceKey: next}, SetOptions(merge: true));
        return next;
      });
      await prefs.setInt(balanceKey, updated);
      await prefs.setBool(_pendingSyncKey, false);
      return updated;
    } catch (e) {
      log(
        'Firestore balance update failed, using local cache: $e',
        name: 'UserCreditsManager',
      );
      final current = prefs.getInt(balanceKey) ?? 0;
      final next = update(current);
      await prefs.setInt(balanceKey, next);
      await prefs.setBool(_pendingSyncKey, true);
      return next;
    }
  }

  /// Sets Pro status and (re)fills the balance to [planTier]'s full pool —
  /// pools refill each cycle rather than accumulate. Call only for an
  /// actual purchase or renewal (see [downgradeToFree] for a lapse).
  ///
  /// If the device was on the free tier right before this call, its free
  /// balance is snapshotted so a later [downgradeToFree] can restore it.
  Future<void> setPro(bool isPro, String planTier) async {
    final prefs = await SharedPreferences.getInstance();
    final udid = await _deviceUdid();

    var preProBalance = prefs.getInt(_preProBalanceKey) ?? 0;
    if (isPro && !(prefs.getBool(proStatusKey) ?? false)) {
      preProBalance = prefs.getInt(balanceKey) ?? 0;
    }

    final pool = creditPoolsProvider().forTier(planTier);
    final data = {
      proStatusKey: isPro,
      planTierKey: planTier,
      balanceKey: pool,
      _preProBalanceKey: preProBalance,
    };

    var pending = false;
    try {
      await _userDoc(udid).set(data, SetOptions(merge: true));
    } catch (e) {
      log(
        'Firestore setPro write failed, local cache still updated: $e',
        name: 'UserCreditsManager',
      );
      pending = true;
    }
    await prefs.setBool(proStatusKey, isPro);
    await prefs.setString(planTierKey, planTier);
    await prefs.setInt(balanceKey, pool);
    await prefs.setInt(_preProBalanceKey, preProBalance);
    await prefs.setBool(_pendingSyncKey, pending);
  }

  /// Downgrades to free after a subscription lapses — restores the balance
  /// the device had right before it became Pro, rather than a fresh free
  /// pool or 0. Called from `SubscriptionController` when RevenueCat
  /// reports the entitlement is no longer active.
  Future<void> downgradeToFree() async {
    final prefs = await SharedPreferences.getInstance();
    final udid = await _deviceUdid();
    final restored = prefs.getInt(_preProBalanceKey) ?? 0;
    final data = {
      proStatusKey: false,
      planTierKey: 'free',
      balanceKey: restored,
      _preProBalanceKey: 0,
    };

    var pending = false;
    try {
      await _userDoc(udid).set(data, SetOptions(merge: true));
    } catch (e) {
      log(
        'Firestore downgradeToFree write failed, local cache still updated: $e',
        name: 'UserCreditsManager',
      );
      pending = true;
    }
    await prefs.setBool(proStatusKey, false);
    await prefs.setString(planTierKey, 'free');
    await prefs.setInt(balanceKey, restored);
    await prefs.setInt(_preProBalanceKey, 0);
    await prefs.setBool(_pendingSyncKey, pending);
  }

  /// Call once at app startup. On a fresh install (or one that wiped local
  /// storage) this looks up the device's Firestore record by UDID: if one
  /// exists the prior balance/plan is restored; otherwise the free pool is
  /// granted and recorded.
  Future<void> initUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(initializedKey) ?? false) return;

    final udid = await _deviceUdid();
    try {
      final snap = await _userDoc(udid).get();
      if (snap.exists) {
        await _applyRemote(prefs, snap.data()!, defaults: true);
        await prefs.setBool(_pendingSyncKey, false);
        log(
          'restored existing balance for device $udid',
          name: 'UserCreditsManager',
        );
      } else {
        final freePool = creditPoolsProvider().free;
        await _userDoc(udid).set({
          proStatusKey: false,
          planTierKey: 'free',
          balanceKey: freePool,
          _preProBalanceKey: 0,
        });
        await prefs.setBool(proStatusKey, false);
        await prefs.setString(planTierKey, 'free');
        await prefs.setInt(balanceKey, freePool);
        await prefs.setInt(_preProBalanceKey, 0);
        await prefs.setBool(_pendingSyncKey, false);
        log(
          'first time user — granted free pool of $freePool',
          name: 'UserCreditsManager',
        );
      }
    } catch (e) {
      // The read failed, so it's unknown whether this device already has a
      // record. Grant a free pool locally as a guess, flagged via
      // [_pendingInitKey] so it is re-verified before ever being pushed.
      log(
        'Firestore lookup failed on init, granting free pool locally as a guess: $e',
        name: 'UserCreditsManager',
      );
      await prefs.setBool(proStatusKey, false);
      await prefs.setString(planTierKey, 'free');
      await prefs.setInt(balanceKey, creditPoolsProvider().free);
      await prefs.setInt(_preProBalanceKey, 0);
      await prefs.setBool(_pendingInitKey, true);
    }
    await prefs.setBool(initializedKey, true);
  }
}
