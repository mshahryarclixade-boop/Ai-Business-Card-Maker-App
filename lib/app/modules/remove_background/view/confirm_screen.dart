import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/remove_background_controller.dart';

class ConfirmScreen extends GetView<RemoveBackgroundController> {
  const ConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final image = controller.pickedImage.value;

      return Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Positioned(
              top: 150,
              bottom: 200,
              left: 0,
              right: 0,
              child: Image.file(
                image,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(color: Colors.black),

          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: GestureDetector(
                onTap: controller.retake,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: AppColors.textSubtitle,
                        size: 25,
                      ),
                      Text(
                        'Retake',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CHECK CIRCLE
          Positioned(
            bottom: 55,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: controller.confirmAndProcess,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.pillLabelGrey,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}