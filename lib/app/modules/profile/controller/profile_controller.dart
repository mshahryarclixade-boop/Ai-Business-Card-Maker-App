import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/profile_model.dart';

class ProfileController extends GetxController {
  ProfileModel profile = ProfileModel();

  final GetStorage _box = GetStorage();
  static const String _storageKey = 'user_profile';

  final RxBool hasProfile = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool showSuccess = false.obs;

  /// Bumped every time [profile] is written to (save/clear/load), so
  /// widgets that read [profile]'s plain (non-Rx) fields — like the
  /// saved-profile card — can watch this to know when to rebuild,
  /// since `profile` itself isn't an Rx object.
  final RxInt profileVersion = 0.obs;

  // NOTE: cardKey ab controller mein nahi hai. Har ProfileView apni
  // GlobalKey rakhta hai aur capture/share/download ke waqt pass karta hai.
  final RxBool isProcessingCard = false.obs;

  // controls the "⋮" popup (Edit / Share / Download) on the saved-profile card.
  final RxBool showCardMenu = false.obs;

  // Personal Details
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final taglineController = TextEditingController();

  // Professional Details
  final companyNameController = TextEditingController();
  final jobTitleController = TextEditingController();
  final companyWebsiteController = TextEditingController();

  // Contact Details
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();

  // Social Links (dynamic - user can add multiple)
  final RxList<TextEditingController> socialLinkControllers =
      <TextEditingController>[].obs;
  static const int maxSocialLinks = 5;

  final Rx<File?> frontImage = Rx<File?>(null);
  final Rx<File?> coverImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  /// Loads the saved profile (if any) from local storage and syncs it
  /// into the text controllers / image state so the UI reflects it.
  void loadProfile() {
    final saved = _box.read(_storageKey);
    if (saved != null) {
      profile = ProfileModel.fromJson(Map<String, dynamic>.from(saved));
    }

    firstNameController.text = profile.firstName;
    lastNameController.text = profile.lastName;
    taglineController.text = profile.tagline;

    companyNameController.text = profile.companyName;
    jobTitleController.text = profile.jobTitle;
    companyWebsiteController.text = profile.companyWebsite;

    emailController.text = profile.email;
    phoneController.text = profile.phone;
    locationController.text = profile.location;

    for (final c in socialLinkControllers) {
      c.dispose();
    }
    socialLinkControllers.clear();
    for (final link in profile.socialLinks) {
      socialLinkControllers.add(TextEditingController(text: link));
    }

    frontImage.value = (profile.frontImagePath != null &&
        profile.frontImagePath!.isNotEmpty &&
        File(profile.frontImagePath!).existsSync())
        ? File(profile.frontImagePath!)
        : null;
    coverImage.value = (profile.coverImagePath != null &&
        profile.coverImagePath!.isNotEmpty &&
        File(profile.coverImagePath!).existsSync())
        ? File(profile.coverImagePath!)
        : null;

    hasProfile.value = profile.firstName.trim().isNotEmpty &&
        profile.lastName.trim().isNotEmpty;

    profileVersion.value++;
  }

  void startBlankProfile() {
    firstNameController.clear();
    lastNameController.clear();
    taglineController.clear();

    companyNameController.clear();
    jobTitleController.clear();
    companyWebsiteController.clear();

    emailController.clear();
    phoneController.clear();
    locationController.clear();

    for (final c in socialLinkControllers) {
      c.dispose();
    }
    socialLinkControllers.clear();

    frontImage.value = null;
    coverImage.value = null;
  }

  Future<String> _persistImage(File source, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = source.path.split('.').last;
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final newPath = '${dir.path}/$fileName';
    final saved = await source.copy(newPath);
    return saved.path;
  }

  Future<void> pickFrontImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked != null) {
      final permanentPath = await _persistImage(File(picked.path), 'front');
      frontImage.value = File(permanentPath);
    }
  }

  Future<void> pickCoverImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      final permanentPath = await _persistImage(File(picked.path), 'cover');
      coverImage.value = File(permanentPath);
    }
  }

  void addSocialLinkField() {
    if (socialLinkControllers.length >= maxSocialLinks) {
      Get.snackbar(
        'Limit Reached',
        'You can add up to $maxSocialLinks custom links.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    socialLinkControllers.add(TextEditingController());
  }

  void removeSocialLinkField(int index) {
    if (index < 0 || index >= socialLinkControllers.length) return;
    socialLinkControllers[index].dispose();
    socialLinkControllers.removeAt(index);
  }

  void saveProfile() {
    profile.firstName = firstNameController.text.trim();
    profile.lastName = lastNameController.text.trim();
    profile.tagline = taglineController.text.trim();

    profile.companyName = companyNameController.text.trim();
    profile.jobTitle = jobTitleController.text.trim();
    profile.companyWebsite = companyWebsiteController.text.trim();

    profile.email = emailController.text.trim();
    profile.phone = phoneController.text.trim();
    profile.location = locationController.text.trim();

    profile.socialLinks = socialLinkControllers
        .map((c) => c.text.trim())
        .where((link) => link.isNotEmpty)
        .toList();

    profile.frontImagePath = frontImage.value?.path;
    profile.coverImagePath = coverImage.value?.path;

    _box.write(_storageKey, profile.toJson());

    hasProfile.value = profile.firstName.trim().isNotEmpty &&
        profile.lastName.trim().isNotEmpty;

    // Bump so anything watching profileVersion (e.g. the saved-profile
    // card, which reads plain fields off `profile`) rebuilds now.
    profileVersion.value++;

    isSaving.value = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      isSaving.value = false;
      showSuccess.value = true;

      Future.delayed(const Duration(milliseconds: 3500), () {
        showSuccess.value = false;
        if (Get.key.currentState?.canPop() ?? false) {
          Get.back();
        }
      });
    });
  }

  /// Clears the saved profile from both memory and disk.
  void clearProfile() {
    _box.remove(_storageKey);
    profile = ProfileModel();
    hasProfile.value = false;
    loadProfile(); // also bumps profileVersion
  }

  void clearSuccess() {
    showSuccess.value = false;
  }

  void toggleCardMenu() {
    showCardMenu.value = !showCardMenu.value;
  }

  void closeCardMenu() {
    showCardMenu.value = false;
  }

  // ---------------------------------------------------------------------
  // Share / Download — capture the card (via the given key's RepaintBoundary)
  // as a PNG and hand it off to the share sheet or the photo gallery.
  // ---------------------------------------------------------------------

  Future<Uint8List?> _captureCardImage(GlobalKey key) async {
    try {
      // Let any pending frame finish building before we snapshot it.
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> shareCard(GlobalKey key) async {
    isProcessingCard.value = true;
    final bytes = await _captureCardImage(key);
    isProcessingCard.value = false;

    if (bytes == null) {
      Get.snackbar(
        'Error',
        'Could not prepare the card for sharing.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/business_card_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Check out my business card!',
    );
  }

  Future<void> downloadCard(GlobalKey key) async {
    isProcessingCard.value = true;
    final bytes = await _captureCardImage(key);
    isProcessingCard.value = false;

    if (bytes == null) {
      Get.snackbar(
        'Error',
        'Could not prepare the card for download.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    try {
      await Gal.putImageBytes(
        bytes,
        name: 'business_card_${DateTime.now().millisecondsSinceEpoch}',
      );
      Get.snackbar(
        'Downloaded',
        'Card saved to your photo gallery.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not save to gallery. Please check photo permissions.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    taglineController.dispose();

    companyNameController.dispose();
    jobTitleController.dispose();
    companyWebsiteController.dispose();

    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();

    for (final c in socialLinkControllers) {
      c.dispose();
    }

    super.onClose();
  }
}