import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../template/model/template_item.dart';
import '../controller/home_controller.dart';

class HomeTemplatesSection extends GetView<HomeController> {
  const HomeTemplatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<RecentDesignsService>();
    final templates = controller.templates;

    return Obx(() {
      // Only shown together with the user's card.
      if (service.designs.isEmpty) return const SizedBox.shrink();
      if (templates.isLoading.value) return const SizedBox.shrink();

      final list = templates.allTemplates
          .where((t) => t.orientation == TemplateOrientation.horizontal)
          .toList();
      if (list.isEmpty) return const SizedBox.shrink();

      final selected = controller.previewTemplate.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Free Templates',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = list[index];
                final isSelected = selected?.id == item.id;

                return GestureDetector(
                  onTap: () => controller.previewTemplateTap(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 215,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        item.frontImagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    });
  }
}