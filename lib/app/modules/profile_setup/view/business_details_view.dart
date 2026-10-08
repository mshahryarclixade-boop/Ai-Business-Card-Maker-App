import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/business_details_controller.dart';
import '../widgets/business_logo_widgets.dart';
import '../widgets/profile_fields.dart';
import '../widgets/profile_primary_button.dart';
import '../widgets/profile_step_header.dart';

class BusinessDetailsView extends GetView<BusinessDetailsController> {
  const BusinessDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(BusinessDetailsController());

    return Scaffold(
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
                    const ProfileStepHeader(step: 2),
                    const SizedBox(height: 24),
                    const Text(
                      'Introduce your work.',
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
                    ProfileTextField(
                      label: 'Company name',
                      hint: 'Clixade',
                      controller: controller.companyController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 28),
                    ProfileTextField(
                      label: 'Designation',
                      hint: 'Product Designer',
                      controller: controller.designationController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 28),
                    const _LogoLabel(),
                    const SizedBox(height: 14),
                    Obx(
                          () => Row(
                        children: [
                          Expanded(
                            child: LogoOptionCard(
                              icon: Icons.add_photo_alternate_outlined,
                              label: 'Upload from gallery',
                              selected:
                              controller.mode.value == LogoMode.gallery,
                              onTap: controller.pickFromGallery,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: LogoOptionCard(
                              icon: Icons.language_rounded,
                              label: 'Company Website',
                              selected:
                              controller.mode.value == LogoMode.website,
                              onTap: controller.selectWebsite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(() {
                      if (controller.mode.value != LogoMode.website) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.profileHintBorder,
                          ),
                          const SizedBox(height: 20),
                          ProfileTextField(
                            label: 'Company website',
                            hint: 'https://yourcompany.com',
                            controller: controller.websiteController,
                            focusNode: controller.websiteFocus,
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            textColor: AppColors.profileLink,
                            onChanged: controller.onWebsiteChanged,
                            onSubmitted: (_) =>
                                controller.findLogoFromWebsite(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                    Obx(() {
                      if (controller.isFetching.value) {
                        return const LogoSearchingCard();
                      }
                      final bytes = controller.logoBytes.value;
                      if (bytes != null) {
                        return LogoPreviewCard(
                          bytes: bytes,
                          name: controller.logoName.value,
                          onRemove: controller.removeLogo,
                        );
                      }
                      if (controller.logoNotFound.value &&
                          controller.mode.value == LogoMode.website) {
                        return LogoNotFoundNotice(
                          onUpload: controller.pickFromGallery,
                          onContinueWithout: controller.continueWithoutLogo,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ProfilePrimaryButton(
                label: 'Create my first card',
                onTap: controller.onCreateCard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoLabel extends StatelessWidget {
  const _LogoLabel();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      const TextSpan(
        text: 'Company logo',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color: AppColors.splashTextPrimary,
        ),
        children: [
          TextSpan(
            text: ' . Optional',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.splashTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}