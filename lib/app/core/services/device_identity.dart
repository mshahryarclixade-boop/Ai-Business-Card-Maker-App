import 'dart:developer';

import 'package:flutter_udid/flutter_udid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who this user is, for `users/{user_id}` and `ai_usage/{user_id}`.
///
/// `user_id` is the device's ACTUAL id, not a hash:
///  * Android: `Settings.Secure.ANDROID_ID`. It stays the same across app
///    uninstall / reinstall (same signing key, same Android user) and changes
///    only on a factory reset. It is re-read from the system on every start,
///    so even cleared app data gives the same id.
///  * iOS: a UUID kept in the Keychain (first `identifierForVendor`), which
///    survives uninstall / reinstall. It is device-only (not iCloud synced), so
///    an erased or replaced phone gets a new one.
///
/// A subscriber who moves to a new phone gets the ORIGINAL id back: the server
/// verifies the purchase with RevenueCat and answers with it; [adopt] stores
/// it and every later request uses it ([userId]).
///
/// Records saved before this change were keyed by the SHA-256 of the raw id
/// ([legacyHashId]); the server moves them to [rawDeviceId] and keeps an alias.
abstract final class DeviceIdentity {
  static const _rawKey = 'device_raw_id';
  static const _legacyKey = 'device_udid'; // the old cached hash
  static const _overrideKey = 'user_id_override';

  static String? _raw;
  static String? _override;
  static bool _overrideLoaded = false;

  /// For tests: forgets the in-memory copies.
  static void resetForTest() {
    _raw = null;
    _override = null;
    _overrideLoaded = false;
  }

  /// The device's actual id, read from the system (the saved copy is only a
  /// fallback when the system cannot answer).
  static Future<String> rawDeviceId() async {
    final known = _raw;
    if (known != null) return known;
    final prefs = await SharedPreferences.getInstance();
    String? id;
    try {
      id = (await FlutterUdid.udid).trim();
    } catch (e) {
      log('device id unavailable from the system: $e', name: 'DeviceIdentity');
    }
    if (id != null && id.isNotEmpty) {
      if (prefs.getString(_rawKey) != id) await prefs.setString(_rawKey, id);
      return _raw = id;
    }
    final saved = prefs.getString(_rawKey);
    if (saved != null && saved.isNotEmpty) return _raw = saved;
    throw StateError('device id unavailable');
  }

  /// The SHA-256 id older versions used (a hash of [rawDeviceId]).
  static Future<String> legacyHashId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_legacyKey);
    if (cached != null && cached.isNotEmpty) return cached;
    final hash = await FlutterUdid.consistentUdid;
    await prefs.setString(_legacyKey, hash);
    return hash;
  }

  /// The id this user's records are kept under: the recovered original id
  /// when there is one, else the device's own.
  static Future<String> userId() async {
    if (!_overrideLoaded) {
      final prefs = await SharedPreferences.getInstance();
      _override = prefs.getString(_overrideKey);
      _overrideLoaded = true;
    }
    return _override ?? await rawDeviceId();
  }

  /// [userId], or null when the device id cannot be read.
  static Future<String?> userIdOrNull() async {
    try {
      return await userId();
    } catch (e) {
      log('user id unavailable: $e', name: 'DeviceIdentity');
      return null;
    }
  }

  /// Switches to [id] (the original id of a recovered subscriber). The device's
  /// own id switches back by passing it again.
  static Future<void> adopt(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await rawDeviceId();
    if (id == raw) {
      await prefs.remove(_overrideKey);
      _override = null;
    } else {
      await prefs.setString(_overrideKey, id);
      _override = id;
    }
    _overrideLoaded = true;
  }
}
