import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/services/profile_scope.dart';
import '../model/qr_entry.dart';

/// The active profile's saved QR codes (newest first), kept on the device.
abstract final class QrStore {
  static const _entriesKey = 'qr_entries';
  static const _seenKey = 'qr_intro_seen';
  static const _selectedKey = 'qr_selected_id';

  static final entries = <QrEntry>[].obs;

  /// The first-time "Custom QR code" screen has been through once: from now
  /// on the QR button opens the saved codes instead.
  static final introSeen = false.obs;

  static bool _loaded = false;

  /// The code the user picked with "Preview", or null to show the newest.
  static final selectedId = RxnString();

  /// The QR code Home and "Show QR Code" show: the one picked with Preview, or
  /// else the newest one; null if there are none.
  static QrEntry? get defaultEntry {
    final id = selectedId.value;
    if (id != null) {
      for (final e in entries) {
        if (e.id == id) return e;
      }
    }
    return entries.isEmpty ? null : entries.first;
  }

  /// Makes [id] the code Home shows (its saved data, not a new code).
  static void select(String id) {
    if (!entries.any((e) => e.id == id)) return;
    selectedId.value = id;
    _save();
  }

  /// Reads the active profile's QR codes once.
  static void load() {
    if (_loaded) return;
    _loaded = true;
    _read();
  }

  /// Shows the active profile's QR codes (after a profile switch).
  static void reload() {
    _loaded = true;
    _read();
  }

  static void _read() {
    final box = GetStorage();
    final list = <QrEntry>[];
    try {
      final raw = box.read<String>(ProfileScope.key(_entriesKey));
      if (raw != null) {
        for (final m in (jsonDecode(raw) as List).whereType<Map>()) {
          final e = QrEntry.fromJson(Map<String, dynamic>.from(m));
          if (e != null) list.add(e);
        }
      }
    } catch (_) {}
    entries.assignAll(list);
    introSeen.value =
        box.read<bool>(ProfileScope.key(_seenKey)) == true || list.isNotEmpty;
    final picked = box.read<String>(ProfileScope.key(_selectedKey));
    selectedId.value = picked != null && list.any((e) => e.id == picked) ? picked : null;
  }

  static void _save() {
    final box = GetStorage();
    try {
      box.write(
        ProfileScope.key(_entriesKey),
        jsonEncode([for (final e in entries) e.toJson()]),
      );
      box.write(ProfileScope.key(_seenKey), introSeen.value);
      box.write(ProfileScope.key(_selectedKey), selectedId.value);
    } catch (_) {}
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Adds a new code at the top, or replaces the one with the same id.
  static void put(QrEntry e) {
    final i = entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      entries[i] = e;
    } else {
      entries.insert(0, e);
      selectedId.value = null; // a new code is shown first, as before
    }
    introSeen.value = true;
    _save();
  }

  static void remove(String id) {
    entries.removeWhere((e) => e.id == id);
    if (selectedId.value == id) selectedId.value = null;
    _save();
  }

  /// Back to nothing (tests, sign-out).
  static void clear() {
    _loaded = true;
    entries.clear();
    selectedId.value = null;
    introSeen.value = false;
    final box = GetStorage();
    try {
      box.remove(ProfileScope.key(_entriesKey));
      box.remove(ProfileScope.key(_seenKey));
      box.remove(ProfileScope.key(_selectedKey));
    } catch (_) {}
  }
}
