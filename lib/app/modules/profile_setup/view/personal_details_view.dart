import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/profile_setup_controller.dart';
import '../widgets/profile_fields.dart';
import '../widgets/profile_hint_card.dart';
import '../widgets/profile_primary_button.dart';
import '../widgets/profile_step_header.dart';

class PersonalDetailsView extends GetView<ProfileSetupController> {
  const PersonalDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProfileSetupController());

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.splashBg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProfileStepHeader(step: 1),
                      const SizedBox(height: 24),
                      const Text(
                        'Let’s start with\nyou',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: 0,
                          color: AppColors.splashTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Obx(
                            () => ProfileTextField(
                          label: 'Full name',
                          hint: 'Alex Morgan',
                          controller: controller.fullNameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          errorText: controller.nameError.value,
                          onChanged: (_) => controller.nameError.value = null,
                          onSubmitted: (_) =>
                              controller.emailFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Obx(
                            () => ProfileTextField(
                          label: 'Email address',
                          hint: 'Your@company.com',
                          controller: controller.emailController,
                          focusNode: controller.emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          errorText: controller.emailError.value,
                          onChanged: (_) => controller.emailError.value = null,
                          onSubmitted: (_) =>
                              controller.phoneFocus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Obx(
                            () => ProfilePhoneField(
                          controller: controller.phoneController,
                          focusNode: controller.phoneFocus,
                          initialDialCode: controller.dialCode.value,
                          onCountryChanged: (c) =>
                          controller.dialCode.value = c.dialCode ?? '+92',
                          errorText: controller.phoneError.value,
                          onChanged: (_) => controller.phoneError.value = null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const ProfileHintCard(
                        text:
                        'Include your country code. You can edit these details later',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ProfilePrimaryButton(
                  label: 'Continue',
                  onTap: controller.onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}