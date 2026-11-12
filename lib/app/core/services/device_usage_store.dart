import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// What one read of `devices/{deviceId}` returned.
class DeviceRead {
  const DeviceRead(this.data, {this.fromCache = false});

  /// Null: the document does not exist (only trustworthy when not [fromCache]).
  final Map<String, dynamic>? data;
  final bool fromCache;
}

/// Where the per-device document lives. The app talks to Firestore directly
/// (no Cloud Functions); `firestore.rules` let it touch only `devices/{id}`.
abstract class DeviceStore {
  Future<DeviceRead> read(String id);
  Future<void> create(String id, Map<String, dynamic> data);

  /// Dotted field paths are allowed (`counters.scan.used`).
  Future<void> update(String id, Map<String, dynamic> fields);
}

void _debug(String message) {
  log(message, name: 'DeviceUsage');
  debugPrint('[DeviceUsage] $message'); // visible in `flutter run` / logcat
}

class FirestoreDeviceStore implements DeviceStore {
  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      FirebaseFirestore.instance.collection('devices').doc(id);

  @override
  Future<DeviceRead> read(String id) async {
    try {
      // The server first; offline or slow (4 s): what is saved on the phone.
      final snap = await _doc(id).get().timeout(const Duration(seconds: 4));
      _debug('READ devices/$id ok: exists=${snap.exists} fromCache=${snap.metadata.isFromCache}');
      return DeviceRead(snap.exists ? snap.data() : null, fromCache: snap.metadata.isFromCache);
    } catch (e) {
      try {
        final snap = await _doc(id).get(const GetOptions(source: Source.cache));
        _debug('READ devices/$id from the phone (server unavailable: $e) exists=${snap.exists}');
        return DeviceRead(snap.exists ? snap.data() : null, fromCache: true);
      } catch (e2) {
        _debug('READ devices/$id FAILED: $e2');
        rethrow;
      }
    }
  }

  @override
  Future<void> create(String id, Map<String, dynamic> data) async {
    try {
      await _doc(id).set(data);
      _debug('WRITE devices/$id created (free, counters 0)');
    } catch (e) {
      _debug('WRITE devices/$id create FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<void> update(String id, Map<String, dynamic> fields) async {
    try {
      await _doc(id).update(fields);
      _debug('WRITE devices/$id ok: ${fields.keys.join(', ')}');
    } catch (e) {
      _debug('WRITE devices/$id FAILED (${fields.keys.join(', ')}): $e');
      rethrow;
    }
  }
}
