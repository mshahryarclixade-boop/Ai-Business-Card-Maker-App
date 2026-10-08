import '../../profile_setup/model/user_profile_data.dart';
import '../../profile_setup/service/profile_store.dart';
import '../model/profile_model.dart';

class ProfileRepository {
  /// Returns the saved profile, or null if the user hasn't saved one yet.
  static ProfileModel? getSavedProfile() {
    final store = ProfileStore.to;
    if (!store.hasProfile) return null;
    return _fromUserProfile(store.profile.value);
  }

  static bool get hasSavedProfile => getSavedProfile() != null;

  static ProfileModel _fromUserProfile(UserProfileData d) {
    final parts = d.fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return ProfileModel(
      firstName: firstName,
      lastName: lastName,
      companyName: d.companyName,
      jobTitle: d.designation,
      companyWebsite: d.website,
      email: d.email,
      phone: d.phone,
    );
  }
}