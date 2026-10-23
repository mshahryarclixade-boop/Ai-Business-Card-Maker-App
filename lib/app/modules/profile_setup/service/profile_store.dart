import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/services/profile_scope.dart';
import '../model/user_profile_data.dart';

class ProfileStore extends GetxService {
  static const _baseKey = 'user_profile_data';

  /// Storage key of the active profile's details.
  static String get _key => ProfileScope.key(_baseKey);

  static ProfileStore get to => Get.isRegistered<ProfileStore>()
      ? Get.find<ProfileStore>()
      : Get.put(ProfileStore(), permanent: true);

  final _box = GetStorage();
  final Rx<UserProfileData> profile = const UserProfileData().obs;

  bool get hasProfile => profile.value.fullName.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  /// Loads the active profile's details (empty if it has none yet). Called
  /// at start-up and whenever the user switches profile.
  void reload() {
    profile.value = readStored(ProfileScope.id) ?? const UserProfileData();
  }

  /// The saved details of any profile, or null if it has none.
  static UserProfileData? readStored(String id) {
    final raw = GetStorage().read<String>(ProfileScope.key(_baseKey, id));
    if (raw == null) return null;
    try {
      return UserProfileData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupt data: start empty
    }
  }

  /// Saves the details of any profile. The active one is updated live.
  void writeStored(String id, UserProfileData data) {
    _box.write(ProfileScope.key(_baseKey, id), jsonEncode(data.toJson()));
    if (id == ProfileScope.id) profile.value = data;
  }

  void savePersonal({
    required String fullName,
    required String email,
    required String dialCode,
    required String phoneNumber,
  }) {
    final p = profile.value;
    profile.value = UserProfileData(
      fullName: fullName,
      email: email,
      dialCode: dialCode,
      phoneNumber: phoneNumber,
      companyName: p.companyName,
      designation: p.designation,
      website: p.website,
      logoBytes: p.logoBytes,
      logoName: p.logoName,
    );
    _persist();
  }

  void saveBusiness({
    required String companyName,
    required String designation,
    required String website,
    required Uint8List? logoBytes,
    required String logoName,
  }) {
    final p = profile.value;
    profile.value = UserProfileData(
      fullName: p.fullName,
      email: p.email,
      dialCode: p.dialCode,
      phoneNumber: p.phoneNumber,
      companyName: companyName,
      designation: designation,
      website: website,
      logoBytes: logoBytes,
      logoName: logoName,
    );
    _persist();
  }

  void _persist() {
    _box.write(_key, jsonEncode(profile.value.toJson()));
  }
}