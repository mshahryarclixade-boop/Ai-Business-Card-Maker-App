import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/home_templates_section.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../paywall/view/paywall_view.dart';
import '../../qr_code_generator/view/qr_code_screen.dart';
import '../../settings/view/settings_view.dart';
import '../controller/home_controller.dart';
import '../widgets/my_card_section.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());

    // final service = Get.find<RecentDesignsService>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },

      // Stack so the "new card" FAB can float above the page content.
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  // Fixed top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 15, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Business Card Maker',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.titleDark,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.to(
                                      () => const PaywallView(),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: AppColors.cardWhite,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const FaIcon(
                                  FontAwesomeIcons.crown,
                                  size: 18,
                                  color: Color(0xFFF5A623),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _RoundIconButton(
                              icon: Icons.settings_outlined,
                              iconColor: AppColors.titleDark,
                              onTap: () {
                                Get.to(
                                      () => const SettingsView(),
                                  transition: Transition.rightToLeft,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const MyCardSection(),
                          const HomeTemplatesSection(),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FAB: only when the user already has recent designs.
          // Positioned(
          //   right: 15,
          //   bottom: MediaQuery.of(context).padding.bottom + 37,
          //   child: Obx(() {
          //     if (service.designs.isEmpty) return const SizedBox.shrink();
          //
          //     return ContactsFab(onTap: () => openOrientationSheet(context));
          //   }),
          // ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }
}