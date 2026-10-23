import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/services/profile_scope.dart';
import '../../profile_setup/service/profile_store.dart';
import '../model/email_signature.dart';

/// The user's saved email signatures, kept on the device. Free users can
/// have [freeLimit]; Pro users any number.
abstract final class EmailSignatureStore {
  static const _baseKey = 'email_signatures';
  static String get _key => ProfileScope.key(_baseKey);
  static const freeLimit = 1;

  static final signatures = <EmailSignature>[].obs;

  /// The signature shown (and copied) on the "Add to your email" screen.
  static final activeId = ''.obs;

  static bool _loaded = false;

  static EmailSignature? get active {
    for (final s in signatures) {
      if (s.id == activeId.value) return s;
    }
    return signatures.isEmpty ? null : signatures.last;
  }

  static bool canCreate({required bool isPro}) =>
      isPro || signatures.length < freeLimit;

  /// Shows the active profile's signatures (after a profile switch).
  static void reload() {
    _loaded = false;
    signatures.clear();
    activeId.value = '';
    load();
  }

  /// Reads the saved signatures once (memory is the truth afterwards).
  static void load() {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = GetStorage().read<String>(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => EmailSignature.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      signatures.assignAll(list);
    } catch (_) {}
  }

  static void _save() {
    try {
      GetStorage().write(
        _key,
        jsonEncode([for (final s in signatures) s.toJson()]),
      );
    } catch (_) {}
  }

  /// Adds a new signature or replaces the one with the same id; it becomes
  /// the active one.
  static void put(EmailSignature s) {
    final i = signatures.indexWhere((e) => e.id == s.id);
    if (i >= 0) {
      signatures[i] = s;
    } else {
      signatures.add(s);
    }
    activeId.value = s.id;
    _save();
  }

  /// Shows [id] in the "Add to your email" preview/copy area.
  static void setActive(String id) => activeId.value = id;

  /// Deletes a signature. If it was the active one, the last remaining
  /// signature becomes active.
  static void remove(String id) {
    signatures.removeWhere((e) => e.id == id);
    if (activeId.value == id) activeId.value = '';
    _save();
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// A fresh signature filled from the business card. Without a card yet
  /// (or in previews), sample details are used.
  static EmailSignature draftFromProfile() {
    final p = Get.isRegistered<ProfileStore>()
        ? ProfileStore.to.profile.value
        : null;
    if (p == null || p.fullName.trim().isEmpty) {
      return EmailSignature(
        id: newId(),
        fullName: 'Ayesha Raza',
        jobTitle: 'Product Designer',
        company: 'Northwind Studio',
        phone: '+92 300 1234567',
        website: 'northwind.co',
        logo: null,
      );
    }
    return EmailSignature(
      id: newId(),
      fullName: p.fullName.trim(),
      jobTitle: p.designation.trim(),
      company: p.companyName.trim(),
      phone: p.phone.trim(),
      website: p.website.trim(),
      logo: p.hasLogo ? p.logoBytes : null,
    );
  }

  /// Back to nothing (tests, sign-out).
  static void clear() {
    _loaded = true;
    signatures.clear();
    activeId.value = '';
    try {
      GetStorage().remove(_key);
    } catch (_) {}
  }
}
