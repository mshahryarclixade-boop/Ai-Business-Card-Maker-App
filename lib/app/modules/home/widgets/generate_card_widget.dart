import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../ai_card_generator/view/ai_card_generator_view.dart';
import '../controller/home_controller.dart';
import '../../../core/translations/tr_extension.dart';

class GenerateCardWidget extends StatelessWidget {
  final HomeController controller;

  const GenerateCardWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.generateCardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'home_generate_title'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'home_generate_subtitle'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18), // Spacer() ki jagah fixed, consistent gap
          Container(
            height: 39, // 40 se 46 — reference me input thoda taller hai
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Center(
              child: TextField(
                controller: controller.promptController,
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                textAlignVertical: TextAlignVertical.center,
                // vertical centering
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  color: AppColors.titleDark,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'home_generate_hint'.tr,
                  hintStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.pillLabelGrey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // "Generate with AI" button

          Center(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  final prompt = controller.promptController.text.trim();

                  await Get.to(() => AiCardGeneratorView(initialPrompt: prompt));

                  controller.promptController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.22),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 13),
                    const SizedBox(width: 8),
                    Text(
                      'home_generate_button'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}