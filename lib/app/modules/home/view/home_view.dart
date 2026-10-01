import 'package:ai_business_card_maker/app/modules/ai_card_generator/view/ai_card_generator_view.dart';
import 'package:ai_business_card_maker/app/modules/remove_background/view/remove_background_view.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/view/scan_card_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../contacts/widgets/contacts_fab.dart';
import '../../custom_create/view/card_editor_view.dart';
import '../../paywall/view/paywall_view.dart';
import '../../qr_code_generator/view/qr_code_screen.dart';
import '../../settings/view/settings_view.dart';
import '../controller/home_controller.dart';
import '../widgets/custom_create_card.dart';
import '../widgets/feature_grid.dart';
import '../widgets/generate_card_widget.dart';
import '../widgets/recent_design_card.dart';
import 'all_recent_designs_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());

    final service = Get.find<RecentDesignsService>();

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
                          // Generate card
                          GenerateCardWidget(controller: controller),
                          const SizedBox(height: 16),

                          // 4-item feature grid
                          FeatureGrid(
                            items: [
                              FeatureItem(
                                icon: Icons.auto_awesome_outlined,
                                label: 'AI\nCreate',
                                onTap: () {
                                  Get.to(
                                        () => const AiCardGeneratorView(),
                                    transition: Transition.rightToLeft,
                                  );
                                },
                              ),
                              FeatureItem(
                                icon: 'assets/icons/scan2.png',
                                label: 'Scan\nCard',
                                onTap: () {
                                  Get.to(
                                        () => const ScanCardView(),
                                    transition: Transition.rightToLeft,
                                  );
                                },
                              ),
                              FeatureItem(
                                icon: Icons.qr_code_2_rounded,
                                label: 'Generate\nQR',
                                onTap: () {
                                  Get.to(
                                        () => const CustomQrCodeScreen(),
                                    transition: Transition.rightToLeft,
                                  );
                                },
                              ),
                              FeatureItem(
                                icon: 'assets/icons/bg.png',
                                label: 'Remove Background',
                                onTap: () {
                                  Get.to(
                                        () => const RemoveBackgroundView(),
                                    transition: Transition.rightToLeft,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Obx(() {
                            if (service.designs.isNotEmpty) {
                              return const SizedBox.shrink();
                            }

                            return const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Custom Create',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.titleDark,
                                  ),
                                ),
                                SizedBox(height: 12),
                                CustomCreateCard(),
                                SizedBox(height: 16),
                              ],
                            );
                          }),

                          // Recent Designs
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Designs',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.titleDark,
                                ),
                              ),

                              GestureDetector(
                                onTap: () => Get.to(
                                      () => const AllRecentDesignsView(),
                                  transition: Transition.rightToLeft,
                                ),
                                child: Row(
                                  children: const [
                                    Text(
                                      'View all',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSubtitle,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            height: 130,
                            child: Obx(() {
                              final list = service.designs;

                              if (list.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No recent designs yet',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 13,
                                      color: AppColors.textSubtitle,
                                    ),
                                  ),
                                );
                              }

                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final design = list[index];

                                  return SizedBox(
                                    width: 200,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: RecentDesignCard(
                                        thumbnailFile: design.file,
                                        onTap: () {
                                          // Open the saved design back in the editor.
                                          Get.to(
                                                () => CardEditorView(
                                              design: design,
                                            ),
                                            transition: Transition.rightToLeft,
                                          );
                                        },
                                        onLongPress: () {
                                          service.delete(design.id);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
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
          Positioned(
            right: 15,
            bottom: MediaQuery.of(context).padding.bottom + 37,
            child: Obx(() {
              if (service.designs.isEmpty) return const SizedBox.shrink();

              return ContactsFab(onTap: () => openOrientationSheet(context));
            }),
          ),
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