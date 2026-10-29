import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart' hide Trans;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/legal_links.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../../paywall/view/paywall_screen.dart';
import '../../profiles/view/profiles_view.dart';
import '../../recent designs/view/my_cards_view.dart';
import '../../../core/translations/app_strings.dart';
import '../../../core/translations/tr_extension.dart';
import 'language_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar.
            SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.titleDark,
                      ),
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Text(
                    'settings_title'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),

                        // Pro banner.
                        const _ProBanner(),

                        const SizedBox(height: 14),

                        // Settings options.
                        _SettingsTile(
                          icon: Icons.person,
                          title: 'settings_profile',
                          onTap: () => Get.to(
                            () => const ProfilesView(),
                            routeName: profilesRoute,
                            transition: Transition.rightToLeft,
                          ),
                        ),
                        const SizedBox(height: 7),

                        _SettingsTile(
                          icon: Icons.card_membership_rounded,
                          title: 'settings_my_cards',
                          onTap: () => Get.to(() => const MyCardsView()),
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.mail,
                          title: 'settings_contact_us',
                          onTap: LegalLinks.openContactUs,
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(icon: Icons.star, title: 'settings_rate_us'),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.share,
                          title: 'settings_share_app',
                        ),
                        const SizedBox(height: 7),

                        // Re-reads the current language label when it changes.
                        ValueListenableBuilder<String>(
                          valueListenable: AppStrings.changes,
                          builder: (context, _, __) => _SettingsTile(
                            icon: Icons.language_rounded,
                            title: 'settings_language_title',
                            value: currentLanguageLabel(),
                            onTap: () => Get.to(
                                  () => const LanguageView(),
                              transition: Transition.rightToLeft,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.assignment_rounded,
                          title: 'settings_privacy_policy',
                          onTap: LegalLinks.openPrivacyPolicy,
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.description_rounded,
                          title: 'settings_terms',
                          onTap: LegalLinks.openTermsOfUse,
                        ),
                        const SizedBox(height: 7),

                        // _SettingsTile(
                        //   icon: Icons.refresh_rounded,
                        //   title: 'Restore Purchase',
                        //   onTap: () => Get.find<SubscriptionController>()
                        //       .restorePurchase(context, source: 'settings'),
                        // ),

                        // const SizedBox(height: 7),

                        // Version text.
                        Text(
                          'settings_version'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppColors.titleDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PRO BANNER
// -----------------------------------------------------------------------------

class _ProBanner extends StatelessWidget {
  const _ProBanner();

  @override
  Widget build(BuildContext context) {
    // The whole banner (incl. "Get Pro") opens the plans paywall.
    return GestureDetector(
      onTap: () => openPaywall(source: 'settings', plans: true),
      child: _banner(),
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF49499D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Banner title.
          PositionedDirectional(
            start: 20,
            top: 20,
            child: Text(
              'settings_pro_banner_title'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          // Get Pro button.
          PositionedDirectional(
            start: 20,
            bottom: 22,
            child: Container(
              height: 33,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.30),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.crown,
                    size: 18,
                    color: const Color(0xFFF5A623),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'settings_get_pro'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Decorative business-card artwork.
          Positioned(
            right: -2,
            top: 8,
            child: SizedBox(
              width: 108,
              height: 116,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Large tilted card.
                  Positioned(
                    right: 35,
                    top: 6,
                    child: Transform.rotate(
                      angle: -math.pi * 0.16,
                      child: Container(
                        width: 58,
                        height: 83,
                        decoration: BoxDecoration(
                          color: const Color(0xFF303080),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              blurRadius: 4,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 8,
                              top: 12,
                              child: Container(
                                width: 34,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6868C7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              top: 21,
                              child: Container(
                                width: 26,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8585D7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              bottom: 13,
                              child: Container(
                                width: 38,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // White business card.
                  Positioned(
                    right: 20,
                    bottom: 15,
                    child: Transform.rotate(
                      angle: math.pi * 0.20,
                      child: Container(
                        width: 59,
                        height: 43,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 25,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3E3E91),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 36,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB0B0BB),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 30,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF77778B),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Small white card at the top-right.
                  Positioned(
                    right: 10,
                    top: 18,
                    child: Transform.rotate(
                      angle: math.pi * 0.25,
                      child: Container(
                        width: 45,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.14),
                              blurRadius: 3,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'settings_banner_card_label'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 5,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF474796),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SETTINGS TILE
// -----------------------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  /// Optional current value shown at the end of the card (e.g. language).
  final String? value;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDCDCE0), width: 1),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title.tr,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.titleDark,
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textGrey,
              ),
            ],
          ],
        ),
      ),
    );
  }
}