import '../../../core/widgets/tap_target.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../../core/widgets/crown_upgrade_button.dart';
import '../../career_studio/widgets/career_hub_sheets.dart';
import '../widgets/ai_toolkit_section.dart';
import '../widgets/home_templates_section.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../settings/view/settings_view.dart';
import '../controller/home_controller.dart';
import '../widgets/my_card_section.dart';
import '../../../core/translations/tr_extension.dart';

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
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 15, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'home_app_title'.tr,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.titleDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            CrownUpgradeButton(
                              size: 36,
                              iconSize: 22,
                              borderRadius: 10,
                              onTap: () => showUpgradeSheet(context),
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
                  const SizedBox(height: 4),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MyCardSection(),
                          const HomeTemplatesSection(),
                          const SizedBox(height: 12),
                          const AiToolkitSection(),
                          const SizedBox(height: 100),
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
    return TapTarget(child: GestureDetector(
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
    ));
  }
}