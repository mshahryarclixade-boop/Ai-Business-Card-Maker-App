import 'dart:typed_data';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';

import '../../../core/translations/tr_extension.dart';
import '../../../routes/app_routes.dart';
import '../service/logo_finder.dart';
import '../widgets/logo_background_sheet.dart';
import '../service/profile_store.dart';

/// [none]: the user has not picked a logo source yet (the default).
enum LogoMode { none, gallery, website }

class BusinessDetailsController extends GetxController {
  final companyController = TextEditingController();
  final designationController = TextEditingController();
  final websiteController = TextEditingController();
  final websiteFocus = FocusNode();

  final Rx<LogoMode> mode = LogoMode.none.obs;
  final RxnString companyError = RxnString();
  final RxnString designationError = RxnString();
  final Rxn<Uint8List> logoBytes = Rxn<Uint8List>();
  final RxString logoName = ''.obs;
  final RxBool isFetching = false.obs;
  final RxBool logoNotFound = false.obs;

  /// The logo as it was before its background was removed; null when the
  /// current logo is untouched. Lets the user undo the removal.
  final Rxn<Uint8List> originalLogoBytes = Rxn<Uint8List>();

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
      mode.value = p.website.isEmpty ? LogoMode.gallery : LogoMode.website;
    } else if (p.website.isNotEmpty) {
      // A website was typed but no logo was found: its field must still show.
      mode.value = LogoMode.website;
    }
    // Look for the logo when the user leaves the website field.
    websiteFocus.addListener(() {
      if (!websiteFocus.hasFocus) findLogoFromWebsite();
    });
  }

  /// Keeps what the user typed when they leave the screen (swipe back,
  /// back button) so it is still there when they return.
  void _saveDraft() {
    ProfileStore.to.saveBusiness(
      companyName: companyName,
      designation: designation,
      website: website,
      logoBytes: logoBytes.value,
      logoName: logoName.value,
    );
  }

  @override
  void onClose() {
    _saveDraft(); // must run before the text controllers are disposed
    companyController.dispose();
    designationController.dispose();
    websiteController.dispose();
    websiteFocus.dispose();
    super.onClose();
  }

  void selectWebsite() => mode.value = LogoMode.website;

  Future<void> pickFromGallery() async {
    mode.value = LogoMode.gallery;
    logoNotFound.value = false;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 90,
      );
      if (file == null) return;

      logoBytes.value = await file.readAsBytes();
      originalLogoBytes.value = null;
      logoName.value = file.name;
      _logoFromWebsite = false;
      await offerBackgroundRemoval();
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'pick logo from gallery',
      );
    }
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

    dynamic result;
    try {
      result = await LogoFinder.find(url);
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'logo finder failed',
      );
      result = null;
    }

    // The user changed the URL while we were fetching; a newer lookup owns the state.
    if (url != _lastLookup) return;

    isFetching.value = false;
    if (result == null) {
      logoNotFound.value = true;
      FirebaseAnalytics.instance.logEvent(name: 'logo_not_found');
      return;
    }
    logoBytes.value = result.bytes;
    originalLogoBytes.value = null;
    logoName.value = result.name;
    _logoFromWebsite = true;
    await offerBackgroundRemoval();
  }

  /// Bottom sheet: remove the logo's background or keep it as it is. Only the
  /// company logo of this screen goes through it.
  @visibleForTesting
  Future<void> offerBackgroundRemoval() async {
    final bytes = logoBytes.value;
    final context = Get.context;
    if (bytes == null || context == null) return;
    final processed = await showLogoBackgroundSheet(context, bytes);
    // Applied, and the logo was not replaced or removed in the meantime.
    if (processed == null || !identical(logoBytes.value, bytes)) return;
    originalLogoBytes.value = bytes;
    logoBytes.value = processed;
  }

  /// Undo: bring back the logo as it was before the background was removed.
  void restoreOriginalLogo() {
    final original = originalLogoBytes.value;
    if (original == null) return;
    logoBytes.value = original;
    originalLogoBytes.value = null;
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
    originalLogoBytes.value = null;
    logoName.value = '';
    _logoFromWebsite = false;
  }

  bool _validate() {
    companyError.value = companyName.isEmpty
        ? 'profile_setup_error_company'.tr
        : null;
    designationError.value = designation.isEmpty
        ? 'profile_setup_error_designation'.tr
        : null;
    return companyError.value == null && designationError.value == null;
  }

  Future<void> onCreateCard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    // The logo stays optional; the company and the designation do not.
    if (!_validate()) return;

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

    FirebaseAnalytics.instance.logEvent(
      name: 'business_details_saved',
      parameters: {
        'has_logo': logoBytes.value != null ? 1 : 0,
        'has_website': website.isNotEmpty ? 1 : 0,
      },
    );

    Get.offAllNamed(Routes.FIRST_CARD);
  }
}
