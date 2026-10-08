import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../model/user_profile_data.dart';

/// Single source of truth for the data entered in the two setup screens.
/// Read it anywhere with: ProfileStore.to.profile.value
class ProfileStore extends GetxService {
  static const _key = 'user_profile_data';

  /// Created on first use, so main.dart doesn't need to change.
  static ProfileStore get to => Get.isRegistered<ProfileStore>()
      ? Get.find<ProfileStore>()
      : Get.put(ProfileStore(), permanent: true);

  final _box = GetStorage();
  final Rx<UserProfileData> profile = const UserProfileData().obs;

  bool get hasProfile => profile.value.fullName.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final raw = _box.read<String>(_key);
    if (raw == null) return;
    try {
      profile.value =
          UserProfileData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt data: start empty.
    }
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