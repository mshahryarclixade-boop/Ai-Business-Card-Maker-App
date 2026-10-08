// import 'dart:math' as math;
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/app_text_styles.dart';
// import '../controller/onboarding_controller.dart';
// import '../widgets/onboarding_screen1.dart';
// import '../widgets/onboarding_screen2.dart';
// import '../widgets/onboarding_screen3.dart';
//
// class OnboardingView extends GetView<OnboardingController> {
//   const OnboardingView({super.key});
//
//   LinearGradient _cssGradient(Size size) {
//     final angle = 168.07 * math.pi / 180;
//     final dx = math.sin(angle);
//     final dy = -math.cos(angle);
//     final length = size.width * dx.abs() + size.height * dy.abs();
//
//     return LinearGradient(
//       begin: Alignment(-dx * length / size.width, -dy * length / size.height),
//       end: Alignment(dx * length / size.width, dy * length / size.height),
//       colors: const [Color(0xFFFFFFFF), Color(0xFFE0E0FF)],
//       stops: const [0.0, 0.9929],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     Get.put(OnboardingController());
//
//     final pages = const [
//       OnboardingScreen1(),
//       OnboardingScreen2(),
//       OnboardingScreen3(),
//     ];
//
//     return Scaffold(
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: BoxDecoration(
//               gradient: _cssGradient(
//                 Size(constraints.maxWidth, constraints.maxHeight),
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   // Skip is hidden on the last page (space is kept so the
//                   // layout doesn't jump).
//                   Obx(
//                         () => Visibility(
//                       visible: controller.currentPage.value != pages.length - 1,
//                       maintainSize: true,
//                       maintainAnimation: true,
//                       maintainState: true,
//                       child: Align(
//                         alignment: Alignment.topRight,
//                         child: Padding(
//                           padding: const EdgeInsets.only(right: 20, top: 8),
//                           child: TextButton(
//                             onPressed: controller.skip,
//                             child: const Text(
//                               'Skip',
//                               style: TextStyle(
//                                 fontFamily: AppTextStyles.fontFamily,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.primary,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: PageView.builder(
//                       controller: controller.pageController,
//                       onPageChanged: controller.onPageChanged,
//                       itemCount: pages.length,
//                       itemBuilder: (context, index) {
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 24),
//                           child: Center(child: pages[index]),
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Obx(
//                         () => Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(
//                         pages.length,
//                             (index) => AnimatedContainer(
//                           duration: const Duration(milliseconds: 250),
//                           margin: const EdgeInsets.symmetric(horizontal: 4),
//                           height: 8,
//                           width:
//                           controller.currentPage.value == index ? 22 : 8,
//                           decoration: BoxDecoration(
//                             color: controller.currentPage.value == index
//                                 ? AppColors.primary
//                                 : AppColors.dotInactive,
//                             borderRadius: BorderRadius.circular(50),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 54,
//                       child: ElevatedButton(
//                         onPressed: controller.next,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.buttonDark,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                         ),
//                         child: Obx(
//                               () => Text(
//                             controller.currentPage.value == pages.length - 1
//                                 ? 'Get Started'
//                                 : 'Next',
//                             style: const TextStyle(
//                               fontFamily: AppTextStyles.fontFamily,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }