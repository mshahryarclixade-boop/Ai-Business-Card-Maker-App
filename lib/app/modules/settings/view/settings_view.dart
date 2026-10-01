import 'dart:math' as math;

import 'package:ai_business_card_maker/app/modules/profile/view/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../recent designs/view/my_cards_view.dart';

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
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.titleDark,
                      ),
                      padding: const EdgeInsets.only(left: 12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const Text(
                    'Settings',
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
                          title: 'Profile',
                          onTap: () => Get.to(() => const ProfileView()),
                        ),
                        const SizedBox(height: 7),

                        _SettingsTile(
                          icon: Icons.card_membership_rounded,
                          title: 'My Cards',
                          onTap: () => Get.to(() => const MyCardsView()),
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.mail,
                          title: 'Contact Us',
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.star,
                          title: 'Rate Us',
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.share,
                          title: 'Share App',
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.assignment_rounded,
                          title: 'Privacy Policy',
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.description_rounded,
                          title: 'Terms and Conditions',
                        ),
                        const SizedBox(height: 7),

                        const _SettingsTile(
                          icon: Icons.refresh_rounded,
                          title: 'Restore Purchase',
                        ),

                        const SizedBox(height: 7),

                        // Version text.
                        const Text(
                          'Version 1.0.0',
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
          const Positioned(
            left: 20,
            top: 20,
            child: Text(
              'Unlock Pro - Create\nWithout Limits',
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
          Positioned(
            left: 20,
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
                  const Text(
                    'Get Pro',
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
                        child: const Center(
                          child: Text(
                            'BUSINESS\nCARD',
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
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
          border: Border.all(
            color: const Color(0xFFDCDCE0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              child: Icon(
                icon,
                size: 17,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.titleDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}