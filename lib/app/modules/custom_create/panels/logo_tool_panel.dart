import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/card_editor_controller.dart';
import '../widgets/panel_shared.dart';
import '../../../core/translations/tr_extension.dart';

class LogoToolPanel extends StatelessWidget {
  final CardEditorController controller;
  const LogoToolPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: controller.addLogoFromGallery,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'custom_create_add_logo'.tr,
                style: const TextStyle(
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
