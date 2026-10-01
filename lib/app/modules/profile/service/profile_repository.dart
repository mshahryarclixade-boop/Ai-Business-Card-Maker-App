import 'package:get_storage/get_storage.dart';

import '../model/profile_model.dart';

/// Read-only, GetX-controller-independent access to the user's saved
/// profile. `ProfileController` owns writing (via `saveProfile()`), but
/// other features — QR Generator, Templates, etc. — just need to *read*
/// the saved profile without depending on ProfileController's lifecycle
/// or having it registered in the widget tree. This mirrors the same
/// GetStorage key/shape ProfileController already writes to, so there's
/// a single source of truth on disk.
class ProfileRepository {
  static const String _storageKey = 'user_profile';
  static final GetStorage _box = GetStorage();

  /// Returns the saved profile, or null if the user hasn't saved one yet.
  static ProfileModel? getSavedProfile() {
    final saved = _box.read(_storageKey);
    if (saved == null) return null;
    return ProfileModel.fromJson(Map<String, dynamic>.from(saved));
  }

  static bool get hasSavedProfile => getSavedProfile() != null;
}
