import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routes/app_routes.dart';
import '../service/logo_finder.dart';
import '../service/profile_store.dart';

enum LogoMode { gallery, website }

class BusinessDetailsController extends GetxController {
  final companyController = TextEditingController();
  final designationController = TextEditingController();
  final websiteController = TextEditingController();
  final websiteFocus = FocusNode();

  final Rx<LogoMode> mode = LogoMode.website.obs;
  final Rxn<Uint8List> logoBytes = Rxn<Uint8List>();
  final RxString logoName = ''.obs;
  final RxBool isFetching = false.obs;
  final RxBool logoNotFound = false.obs;

  final _picker = ImagePicker();
  String _lastLookup = '';
  bool _logoFromWebsite = false;

  String get companyName => companyController.text.trim();
  String get designation => designationController.text.trim();
  String get website => websiteController.text.trim();

  @override
  void onInit() {
    super.onInit();
    final p = ProfileStore.to.profile.value;
    companyController.text = p.companyName;
    designationController.text = p.designation;
    websiteController.text = p.website;
    if (p.hasLogo) {
      logoBytes.value = p.logoBytes;
      logoName.value = p.logoName;
      _lastLookup = p.website; // already have its logo, don't fetch again
      if (p.website.isEmpty) mode.value = LogoMode.gallery;
    }
    // Look for the logo when the user leaves the website field.
    websiteFocus.addListener(() {
      if (!websiteFocus.hasFocus) findLogoFromWebsite();
    });
  }

  void selectWebsite() => mode.value = LogoMode.website;

  Future<void> pickFromGallery() async {
    mode.value = LogoMode.gallery;
    logoNotFound.value = false;
    FocusManager.instance.primaryFocus?.unfocus();

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 90,
    );
    if (file == null) return;

    logoBytes.value = await file.readAsBytes();
    logoName.value = file.name;
    _logoFromWebsite = false;
  }

  void onWebsiteChanged(String _) => logoNotFound.value = false;

  Future<void> findLogoFromWebsite() async {
    final url = website;
    if (mode.value != LogoMode.website) return;
    if (url.isEmpty || url == _lastLookup) return;

    _lastLookup = url;
    logoNotFound.value = false;
    isFetching.value = true;

    // A logo found for the previous URL must not stay attached to a new one.
    if (_logoFromWebsite) _clearLogo();

    final result = await LogoFinder.find(url);

    // The user changed the URL while we were fetching; a newer lookup owns the state.
    if (url != _lastLookup) return;

    isFetching.value = false;
    if (result == null) {
      logoNotFound.value = true;
      return;
    }
    logoBytes.value = result.bytes;
    logoName.value = result.name;
    _logoFromWebsite = true;
  }

  /// "X" on the preview card: the user rejects the logo.
  void removeLogo() {
    _clearLogo();
    logoNotFound.value = false;
  }

  void continueWithoutLogo() {
    _clearLogo();
    logoNotFound.value = false;
  }

  void _clearLogo() {
    logoBytes.value = null;
    logoName.value = '';
    _logoFromWebsite = false;
  }

  Future<void> onCreateCard() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Make sure a logo lookup the user just triggered has finished.
    await findLogoFromWebsite();
    while (isFetching.value) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    ProfileStore.to.saveBusiness(
      companyName: companyName,
      designation: designation,
      website: website,
      logoBytes: logoBytes.value,
      logoName: logoName.value,
    );

    Get.offAllNamed(Routes.FIRST_CARD);
  }

  @override
  void onClose() {
    companyController.dispose();
    designationController.dispose();
    websiteController.dispose();
    websiteFocus.dispose();
    super.onClose();
  }
}