// import 'package:flutter/material.dart';
// import '../../../core/theme/app_colors.dart';
//
// class OnboardingFadedImage extends StatelessWidget {
//   final String asset;
//   final double width;
//   final double? height;
//   final double fadeStart; // 0.0–1.0, where the fade begins (from top)
//   final double shadowWidthFactor; // relative to [width]
//
//   const OnboardingFadedImage({
//     super.key,
//     required this.asset,
//     required this.width,
//     this.height,
//     this.fadeStart = 0.8,
//     this.shadowWidthFactor = 0.62,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.bottomCenter,
//       clipBehavior: Clip.none,
//       children: [
//         // Soft glow shadow sitting behind/under the image
//         Positioned(
//           bottom: 6,
//           child: Container(
//             width: width * shadowWidthFactor,
//             height: 18,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(100),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.primary.withOpacity(0.38),
//                   blurRadius: 28,
//                   spreadRadius: 6,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // The image itself, faded out at the bottom edge
//         ShaderMask(
//           blendMode: BlendMode.dstIn,
//           shaderCallback: (rect) => LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: const [Colors.black, Colors.transparent],
//             stops: [fadeStart, 1.0],
//           ).createShader(rect),
//           child: Image.asset(
//             asset,
//             width: width,
//             height: height,
//             fit: BoxFit.contain,
//           ),
//         ),
//       ],
//     );
//   }
// }