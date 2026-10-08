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
                          // Generate card
                          // GenerateCardWidget(controller: controller),
                          // const SizedBox(height: 16),
                          //
                          // // 4-item feature grid
                          // FeatureGrid(
                          //   items: [
                          //     FeatureItem(
                          //       icon: Icons.auto_awesome_outlined,
                          //       label: 'AI\nCreate',
                          //       onTap: () {
                          //         Get.to(
                          //               () => const AiCardGeneratorView(),
                          //           transition: Transition.rightToLeft,
                          //         );
                          //       },
                          //     ),
                          //     FeatureItem(
                          //       icon: 'assets/icons/scan2.png',
                          //       label: 'Scan\nCard',
                          //       onTap: () {
                          //         Get.to(
                          //               () => const ScanCardView(),
                          //           transition: Transition.rightToLeft,
                          //         );
                          //       },
                          //     ),
                          //     FeatureItem(
                          //       icon: Icons.qr_code_2_rounded,
                          //       label: 'Generate\nQR',
                          //       onTap: () {
                          //         Get.to(
                          //               () => const CustomQrCodeScreen(),
                          //           transition: Transition.rightToLeft,
                          //         );
                          //       },
                          //     ),
                          //     FeatureItem(
                          //       icon: 'assets/icons/bg.png',
                          //       label: 'Remove Background',
                          //       onTap: () {
                          //         Get.to(
                          //               () => const RemoveBackgroundView(),
                          //           transition: Transition.rightToLeft,
                          //         );
                          //       },
                          //     ),
                          //   ],
                          // ),
                          // const SizedBox(height: 16),
                          // Obx(() {
                          //   if (service.designs.isNotEmpty) {
                          //     return const SizedBox.shrink();
                          //   }
                          //
                          //   return const Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Text(
                          //         'Custom Create',
                          //         style: TextStyle(
                          //           fontFamily: AppTextStyles.fontFamily,
                          //           fontSize: 16,
                          //           fontWeight: FontWeight.w700,
                          //           color: AppColors.titleDark,
                          //         ),
                          //       ),
                          //       SizedBox(height: 12),
                          //       CustomCreateCard(),
                          //       SizedBox(height: 16),
                          //     ],
                          //   );
                          // }),

                          // Recent Designs
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     const Text(
                          //       'Recent Designs',
                          //       style: TextStyle(
                          //         fontFamily: AppTextStyles.fontFamily,
                          //         fontSize: 16,
                          //         fontWeight: FontWeight.w700,
                          //         color: AppColors.titleDark,
                          //       ),
                          //     ),
                          //
                          //     GestureDetector(
                          //       onTap: () => Get.to(
                          //             () => const AllRecentDesignsView(),
                          //         transition: Transition.rightToLeft,
                          //       ),
                          //       child: Row(
                          //         children: const [
                          //           Text(
                          //             'View all',
                          //             style: TextStyle(
                          //               fontFamily: AppTextStyles.fontFamily,
                          //               fontSize: 14,
                          //               fontWeight: FontWeight.w500,
                          //               color: AppColors.textSubtitle,
                          //             ),
                          //           ),
                          //           Icon(
                          //             Icons.chevron_right,
                          //             size: 18,
                          //             color: AppColors.primary,
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // const SizedBox(height: 12),

                          // SizedBox(
                          //   height: 130,
                          //   child: Obx(() {
                          //     final list = service.designs;
                          //
                          //     if (list.isEmpty) {
                          //       return const Center(
                          //         child: Text(
                          //           'No recent designs yet',
                          //           style: TextStyle(
                          //             fontFamily: AppTextStyles.fontFamily,
                          //             fontSize: 13,
                          //             color: AppColors.textSubtitle,
                          //           ),
                          //         ),
                          //       );
                          //     }
                          //
                          //     return ListView.separated(
                          //       scrollDirection: Axis.horizontal,
                          //       itemCount: list.length,
                          //       separatorBuilder: (_, __) =>
                          //       const SizedBox(width: 12),
                          //       itemBuilder: (context, index) {
                          //         final design = list[index];
                          //
                          //         return SizedBox(
                          //           width: 200,
                          //           child: ClipRRect(
                          //             borderRadius: BorderRadius.circular(4),
                          //             child: RecentDesignCard(
                          //               thumbnailFile: design.file,
                          //               onTap: () {
                          //                 // Open the saved design back in the editor.
                          //                 Get.to(
                          //                       () => CardEditorView(
                          //                     design: design,
                          //                   ),
                          //                   transition: Transition.rightToLeft,
                          //                 );
                          //               },
                          //               onLongPress: () async {
                          //                 if (await confirmDeleteDesign()) {
                          //                   service.delete(design.id);
                          //                 }
                          //               },
                          //             ),
                          //           ),
                          //         );
                          //       },
                          //     );
                          //   }),
                          // ),
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

// /// Asks the user before a recent design is deleted.
// Future<bool> confirmDeleteDesign() async {
//   final result = await Get.dialog<bool>(
//     Center(
//       child: Material(
//         color: Colors.transparent,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 31),
//           child: Container(
//             width: 332,
//             constraints: const BoxConstraints(minHeight: 188),
//             padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.delete_outline_rounded,
//                   size: 40,
//                   color: Colors.red,
//                 ),
//                 const SizedBox(height: 6),
//                 const Text(
//                   'Delete Design',
//                   style: TextStyle(
//                     fontFamily: AppTextStyles.fontFamily,
//                     fontSize: 20,
//                     height: 1.2,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.titleDark,
//                     decoration: TextDecoration.none,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 const Text(
//                   'Are you sure you want to delete this design?',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontFamily: AppTextStyles.fontFamily,
//                     fontSize: 14,
//                     height: 1.2,
//                     fontWeight: FontWeight.w400,
//                     color: AppColors.titleDark,
//                     decoration: TextDecoration.none,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       width: 120,
//                       height: 32,
//                       child: ElevatedButton(
//                         onPressed: () => Get.back(result: false),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFF1F1F3),
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           minimumSize: Size.zero,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text(
//                           'Cancel',
//                           style: TextStyle(
//                             fontFamily: AppTextStyles.fontFamily,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.titleDark,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     SizedBox(
//                       width: 120,
//                       height: 32,
//                       child: ElevatedButton(
//                         onPressed: () => Get.back(result: true),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.buttonDark,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           minimumSize: Size.zero,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text(
//                           'Delete',
//                           style: TextStyle(
//                             fontFamily: AppTextStyles.fontFamily,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ),
//     barrierDismissible: true,
//   );
//   return result ?? false;
// }

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