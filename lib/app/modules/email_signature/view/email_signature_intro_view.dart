import '../../../core/widgets/crown_upgrade_button.dart';
import '../../../core/widgets/tap_target.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../career_studio/widgets/career_hub_sheets.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../service/email_signature_store.dart';
import '../widgets/signature_card.dart';
import '../widgets/signature_sheets.dart';
import 'email_signature_editor_view.dart';
import 'email_signature_saved_view.dart';

const _introRoute = '/EmailSignatureIntro';

/// Home's email button: the intro for a first signature, otherwise the
/// user's saved signatures. Every screen of the module slides in from the
/// right and has a route name starting with "/EmailSignature".
void openEmailSignature() {
  EmailSignatureStore.load();
  if (EmailSignatureStore.signatures.isEmpty) {
    Get.to(
      () => const EmailSignatureIntroView(),
      routeName: _introRoute,
      transition: Transition.rightToLeft,
    );
  } else {
    Get.to(
      () => const EmailSignatureSavedView(),
      routeName: savedRoute,
      transition: Transition.rightToLeft,
    );
  }
}

/// "Email signature": what it is and how it works. Create my signature opens
/// the New signature screen, pre-filled from the business card.
class EmailSignatureIntroView extends StatelessWidget {
  const EmailSignatureIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = EmailSignatureStore.draftFromProfile();
    final steps = [
      'email_sig_how_1'.tr,
      'email_sig_how_2'.tr,
      'email_sig_how_3'.tr,
    ];
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            CareerAppBar(
              title: 'email_sig_intro_title'.tr,
              trailing: Obx(
                () => signatureIsPro()
                    ? const SizedBox.shrink()
                    // The same crown as Clixa's (size, colours, wiggle).
                    : CrownUpgradeButton(
                        size: 40,
                        iconSize: 22,
                        borderRadius: 12,
                        onTap: () => showUpgradeSheet(context),
                      ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'email_sig_hero_title'.tr,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 22,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'email_sig_hero_message'.tr,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12.5,
                              height: 1.45,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: SignatureCard(sig: sample),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.pillBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'email_sig_how_title'.tr,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.titleDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0; i < steps.length; i++)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                bottom: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primarySoft,
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.onboardingBtnEnd,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      steps[i],
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.titleDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'email_sig_free_note'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.pillBorder)),
              ),
              child: CareerPrimaryButton(
                label: 'email_sig_create'.tr,
                onTap: () => Get.to(
                  () => const EmailSignatureEditorView(),
                  routeName: editorRoute,
                  transition: Transition.rightToLeft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
