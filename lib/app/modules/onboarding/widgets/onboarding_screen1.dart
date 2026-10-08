// import 'package:flutter/material.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../core/theme/app_text_styles.dart';
//
// class OnboardingScreen1 extends StatelessWidget {
//   const OnboardingScreen1({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Stack(
//           clipBehavior: Clip.none,
//           alignment: Alignment.topCenter,
//           children: [
//             // --- PILLS (fixed position, painted first = behind) ---
//             const Positioned(
//               top: -8,
//               left: 3,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _InfoPill(width: 185, iconAsset: 'assets/icons/pill1.png', label: 'Name', value: 'John Doe'),
//                   SizedBox(height: 10),
//                   _InfoPill(width: 259, iconAsset: 'assets/icons/pill2.png', label: 'Name', value: 'General Manager'),
//                   SizedBox(height: 10),
//                   _InfoPill(width: 220, iconAsset: 'assets/icons/pill3.png', label: 'Company', value: 'Apex Creative'),
//                 ],
//               ),
//             ),
//
//             // --- CARD IMAGE
//             Image.asset(
//               'assets/images/onboarding1.png',
//               width: 320,
//               fit: BoxFit.contain,
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 18),
//
//         const Text(
//           'Still handing out boring\nbusiness card?',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontFamily: AppTextStyles.fontFamily,
//             fontSize: 22,
//             height: 1.2,
//             fontWeight: FontWeight.w700,
//             color: AppColors.titleDark,
//           ),
//         ),
//         const SizedBox(height: 8),
//         const Text(
//           'Your first impression deserves better\nthan a plain white card.',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontFamily: AppTextStyles.fontFamily,
//             fontSize: 13,
//             color: AppColors.textSubtitle,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _InfoPill extends StatelessWidget {
//   final double width;
//   final String iconAsset;
//   final String label;
//   final String value;
//
//   const _InfoPill({
//     required this.width,
//     required this.iconAsset,
//     required this.label,
//     required this.value,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: width,
//       height: 62,
//       padding: const EdgeInsets.only(left: 10, right: 12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFFFFF),
//         borderRadius: BorderRadius.circular(500),
//         border: Border.all(color: const Color(0xFFE2E2FF), width: 2),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 43,
//             height: 43,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: const Color(0xFFEEEDFE),
//               borderRadius: BorderRadius.circular(48.86),
//             ),
//             child: Image.asset(
//               iconAsset,
//               width: 25.897729873657227,
//               height: 25.897729873657227,
//               fit: BoxFit.contain,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontFamily: AppTextStyles.fontFamily,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     height: 1.0,
//                     color: Color(0xFF635D70),
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   value,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontFamily: AppTextStyles.fontFamily,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     height: 1.0,
//                     color: Color(0xFF010120),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }