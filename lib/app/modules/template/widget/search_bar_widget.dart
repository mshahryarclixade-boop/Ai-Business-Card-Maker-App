import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/template_controller.dart';

class TemplateSearchBar extends StatelessWidget {
  final TemplateController controller;

  const TemplateSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: controller.isSearching.value ? AppColors.primary : AppColors.pillBorder,
            width: controller.isSearching.value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: controller.isSearching.value ? controller.exitSearch : null,
              child: Icon(
                controller.isSearching.value ? Icons.arrow_back : Icons.search,
                size: 20,
                color: controller.isSearching.value ? AppColors.titleDark : AppColors.pillLabelGrey,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                focusNode: controller.searchFocusNode,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  color: AppColors.titleDark,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search by style or profession...',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.pillLabelGrey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
