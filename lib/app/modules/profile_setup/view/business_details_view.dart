import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../controller/business_details_controller.dart';
import '../widgets/business_logo_widgets.dart';
import '../widgets/profile_fields.dart';
import '../widgets/profile_primary_button.dart';
import '../widgets/profile_step_header.dart';
import '../../../core/translations/tr_extension.dart';

class BusinessDetailsView extends GetView<BusinessDetailsController> {
  const BusinessDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(BusinessDetailsController());

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
                      const ProfileStepHeader(step: 2),
                      const SizedBox(height: 24),
                      Text(
                        'profile_setup_business_title'.tr,
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
                        label: 'profile_setup_business_company_name'.tr,
                        hint: 'profile_setup_business_company_hint'.tr,
                        controller: controller.companyController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 28),
                      ProfileTextField(
                        label: 'profile_setup_business_designation'.tr,
                        hint: 'profile_setup_business_designation_hint'.tr,
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
                                label: 'profile_setup_business_upload_gallery'.tr,
                                selected:
                                controller.mode.value == LogoMode.gallery,
                                onTap: controller.pickFromGallery,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LogoOptionCard(
                                icon: Icons.language_rounded,
                                label: 'profile_setup_business_logo_website'.tr,
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
                              label: 'profile_setup_business_website_label'.tr,
                              hint: 'profile_setup_business_website_hint'.tr,
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
                  label: 'profile_setup_business_create_card'.tr,
                  onTap: controller.onCreateCard,
                ),
              ),
            ],
          ),
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
      TextSpan(
        text: 'profile_setup_business_logo_label'.tr,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.2,
          color: AppColors.splashTextPrimary,
        ),
        children: [
          TextSpan(
            text: 'profile_setup_business_optional'.tr,
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