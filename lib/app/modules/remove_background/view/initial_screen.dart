import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/remove_background_controller.dart';
import '../widget/remove_bg_app_bar.dart';
import '../../../core/translations/tr_extension.dart';

class InitialScreen extends GetView<RemoveBackgroundController> {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RemoveBgAppBar(title: 'remove_bg_initial_title'.tr),

        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // UPDATED: Vector 2 is positioned at the top-right of Vector 1.
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main background remover icon
                      Image.asset(
                        'assets/images/bg_vector_1.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),

                      // Small sparkle/vector placed on the top-right
                      PositionedDirectional(
                        top: -4,
                        end: -4,
                        child: Image.asset(
                          'assets/images/bg_vector_2.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'remove_bg_initial_headline'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleDark,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'remove_bg_initial_powered'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              SizedBox(
                width: 348,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.takePicture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'remove_bg_initial_take_picture'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: 348,
                height: 50,
                child: OutlinedButton(
                  onPressed: controller.uploadFromGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'remove_bg_initial_upload_gallery'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}