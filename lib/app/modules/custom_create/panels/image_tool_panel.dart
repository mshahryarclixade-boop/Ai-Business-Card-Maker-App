import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/card_editor_controller.dart';
import '../widgets/panel_shared.dart';

class ImageToolPanel extends StatelessWidget {
  final CardEditorController controller;
  const ImageToolPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle replacing the back-icon header.
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Upload from Gallery — filled primary button.
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: controller.addImageFromGallery,
              icon: const Icon(Icons.photo_library_outlined,
                  size: 18, color: Colors.white),
              label: const Text(
                'Upload from Gallery',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Take a picture — outlined button, opens the camera.
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: controller.addImageFromCamera,
              icon: Icon(Icons.camera_alt_outlined,
                  size: 18, color: AppColors.primary),
              label: Text(
                'Take a picture',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}