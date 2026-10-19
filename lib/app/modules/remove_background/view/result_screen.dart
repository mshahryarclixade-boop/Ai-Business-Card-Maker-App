import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/remove_background_controller.dart';
import '../widget/remove_bg_app_bar.dart';
import '../../../core/translations/tr_extension.dart';

class ResultScreen extends GetView<RemoveBackgroundController> {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RemoveBgAppBar(title: 'remove_bg_result_title'.tr),

        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(
            child: Obx(() {
              final bytes = controller.resultBytes.value;

              if (bytes == null) {
                return const SizedBox.shrink();
              }

              return SizedBox(
                width: 396,
                height: 380,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            }),
          ),
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 35),
          child: Column(
            children: [
              Obx(
                    () => SizedBox(
                  width: 348,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isDownloading.value
                        ? null
                        : controller.downloadToGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isDownloading.value
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      'remove_bg_result_download'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: 348,
                height: 50,
                child: OutlinedButton(
                  onPressed: controller.shareResult,
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
                    'remove_bg_result_share'.tr,
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