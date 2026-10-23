import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart' hide Trans;
import 'package:get_storage/get_storage.dart';

import '../../../core/services/profile_scope.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../core/translations/tr_extension.dart';
import '../../email_signature/service/email_signature_store.dart';
import '../../home/controller/home_controller.dart';
import '../../profile_setup/model/user_profile_data.dart';
import '../../profile_setup/service/profile_store.dart';
import '../../qr_code_generator/service/qr_store.dart';

/// One profile in the list. Its details, designs, QR codes and signatures
/// live in their own storage keys (see [ProfileScope]).
class ProfileEntry {
  const ProfileEntry({required this.id, this.name = '', required this.createdAt});

  final String id;

  /// A label for profiles without a full name yet.
  final String name;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  static ProfileEntry? fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    return ProfileEntry(
      id: id,
      name: (j['name'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// The user's profiles and which one is active. Switching reloads every
/// per-profile store, so Home and the other screens follow on their own.
abstract final class ProfilesManager {
  static const _key = 'profiles_v1';

  static final profiles = <ProfileEntry>[].obs;
  static final activeId = ProfileScope.defaultId.obs;

  static bool _loaded = false;

  /// Reads the profile list and points [ProfileScope] at the active one. Must
  /// run before any per-profile store loads (start-up).
  static void load() {
    if (_loaded) return;
    _loaded = true;
    _read();
  }

  static void _read() {
    final list = <ProfileEntry>[];
    var active = ProfileScope.defaultId;
    try {
      final raw = GetStorage().read<String>(_key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        for (final p in (m['profiles'] as List? ?? const []).whereType<Map>()) {
          final e = ProfileEntry.fromJson(Map<String, dynamic>.from(p));
          if (e != null) list.add(e);
        }
        active = (m['active'] as String?) ?? active;
      }
    } catch (_) {}
    if (list.isEmpty) {
      // The data saved before profiles existed belongs to the first one.
      list.add(
        ProfileEntry(id: ProfileScope.defaultId, createdAt: DateTime.now()),
      );
      active = ProfileScope.defaultId;
    }
    if (!list.any((e) => e.id == active)) active = list.first.id;
    profiles.assignAll(list);
    activeId.value = active;
    ProfileScope.id = active;
  }

  static void _save() {
    try {
      GetStorage().write(
        _key,
        jsonEncode({
          'active': activeId.value,
          'profiles': [for (final p in profiles) p.toJson()],
        }),
      );
    } catch (_) {}
  }

  static ProfileEntry? byId(String id) =>
      profiles.firstWhereOrNull((e) => e.id == id);

  /// The saved details of [id]; the active profile's live ones.
  static UserProfileData infoOf(String id) {
    if (id == activeId.value && Get.isRegistered<ProfileStore>()) {
      return ProfileStore.to.profile.value;
    }
    return ProfileStore.readStored(id) ?? const UserProfileData();
  }

  /// What to call a profile: its full name, else its label, else "Profile n".
  static String labelOf(ProfileEntry e) {
    final n = infoOf(e.id).fullName.trim();
    if (n.isNotEmpty) return n;
    if (e.name.trim().isNotEmpty) return e.name.trim();
    final i = profiles.indexWhere((x) => x.id == e.id);
    return 'profiles_untitled'.trParams({'n': i + 1});
  }

  /// Adds an empty profile and returns its id.
  static String create({String name = ''}) {
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    profiles.add(ProfileEntry(id: id, name: name, createdAt: DateTime.now()));
    _save();
    return id;
  }

  static void rename(String id, String name) {
    final i = profiles.indexWhere((e) => e.id == id);
    if (i < 0) return;
    profiles[i] = ProfileEntry(
      id: id,
      name: name,
      createdAt: profiles[i].createdAt,
    );
    _save();
  }

  /// Makes [id] the active profile and reloads everything that is per-profile.
  static void switchTo(String id) {
    if (id == activeId.value || byId(id) == null) return;
    activeId.value = id;
    ProfileScope.id = id;
    _save();
    _reloadStores();
  }

  /// Deletes a profile and its data. The last profile can't be deleted
  /// (returns false). Deleting the active one switches to another first.
  static bool delete(String id) {
    if (profiles.length <= 1 || byId(id) == null) return false;
    if (id == activeId.value) {
      switchTo(profiles.firstWhere((e) => e.id != id).id);
    }
    _purge(id);
    profiles.removeWhere((e) => e.id == id);
    _save();
    return true;
  }

  static void _reloadStores() {
    if (Get.isRegistered<ProfileStore>()) ProfileStore.to.reload();
    if (Get.isRegistered<RecentDesignsService>()) {
      Get.find<RecentDesignsService>().reload();
    }
    QrStore.reload();
    EmailSignatureStore.reload();
    // A template previewed on Home belongs to the profile that was open.
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().cancelPreview();
    }
  }

  /// Removes everything a deleted profile stored, including its card images.
  static void _purge(String id) {
    final box = GetStorage();
    try {
      final raw = box.read<String>(ProfileScope.key('recent_designs', id));
      if (raw != null) {
        for (final m in (jsonDecode(raw) as List).whereType<Map>()) {
          for (final k in ['path', 'backPath']) {
            final p = m[k];
            if (p is String) {
              final f = File(p);
              if (f.existsSync()) f.deleteSync();
            }
          }
        }
      }
    } catch (_) {}
    for (final k in ProfileScope.perProfileKeys) {
      try {
        box.remove(ProfileScope.key(k, id));
      } catch (_) {}
    }
  }

  /// Back to one empty profile (tests).
  static void clear() {
    _loaded = true;
    profiles.clear();
    activeId.value = ProfileScope.defaultId;
    ProfileScope.id = ProfileScope.defaultId;
    try {
      GetStorage().remove(_key);
    } catch (_) {}
    _read();
  }
}
