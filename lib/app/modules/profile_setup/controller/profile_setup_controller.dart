import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../service/profile_store.dart';

class ProfileSetupController extends GetxController {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final RxString dialCode = '+92'.obs;

  final RxnString nameError = RxnString();
  final RxnString emailError = RxnString();
  final RxnString phoneError = RxnString();
  final FocusNode emailFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String get fullName => fullNameController.text.trim();
  String get email => emailController.text.trim();

  /// Country code + number, or empty if no number was entered.
  String get phone {
    final number = phoneController.text.trim();
    return number.isEmpty ? '' : '${dialCode.value} $number';
  }

  @override
  void onInit() {
    super.onInit();
    // Start from what was already entered (user came back, or generation
    // failed earlier) instead of an empty form.
    final p = ProfileStore.to.profile.value;
    fullNameController.text = p.fullName;
    emailController.text = p.email;
    phoneController.text = p.phoneNumber;
    if (p.dialCode.isNotEmpty) dialCode.value = p.dialCode;
  }

  bool validatePersonalDetails() {
    nameError.value = null;
    emailError.value = null;
    phoneError.value = null;
    var ok = true;

    if (fullName.isEmpty) {
      nameError.value = 'Please enter your full name';
      ok = false;
    }

    final hasEmail = email.isNotEmpty;
    final number = phoneController.text.trim();
    final hasPhone = number.isNotEmpty;

    if (!hasEmail && !hasPhone) {
      emailError.value = 'Add an email or a phone number';
      phoneError.value = 'Add an email or a phone number';
      ok = false;
    } else {
      if (hasEmail && !_emailRegex.hasMatch(email)) {
        emailError.value = 'Enter a valid email address';
        ok = false;
      }
      if (hasPhone && number.replaceAll(RegExp(r'\D'), '').length < 6) {
        phoneError.value = 'Enter a valid phone number';
        ok = false;
      }
    }
    return ok;
  }

  void onContinue() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!validatePersonalDetails()) return;

    ProfileStore.to.savePersonal(
      fullName: fullName,
      email: email,
      dialCode: dialCode.value,
      phoneNumber: phoneController.text.trim(),
    );
    Get.toNamed(Routes.BUSINESS_DETAILS);
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    super.onClose();
  }
}