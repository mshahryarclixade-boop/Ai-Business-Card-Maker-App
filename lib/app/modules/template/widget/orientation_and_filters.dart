import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/template_controller.dart';

class OrientationTabs extends StatelessWidget {
  final TemplateController controller;

  const OrientationTabs({super.key, required this.controller});

  static const _labelKeys = [
    'template_tab_horizontal',
    'template_tab_vertical',
    'template_tab_saved',
  ];
  static const _icons = [null, null, Icons.favorite];

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
        children: List.generate(_labelKeys.length, (index) {
          final isActive = controller.tabIndex.value == index;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: GestureDetector(
              onTap: () => controller.changeTab(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.2, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.buttonDark : const Color(0xFFEDEDF2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_icons[index] != null) ...[
                      Icon(_icons[index], size: 14, color: isActive ? Colors.white : AppColors.pillLabelGrey),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _labelKeys[index].tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppColors.pillLabelGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
      ),
    );
  }
}

class FilterChipsRow extends StatelessWidget {
  final TemplateController controller;

  const FilterChipsRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: controller.filters.map((filter) {
            final isActive = controller.selectedFilter.value == filter;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: GestureDetector(
                onTap: () => controller.selectFilter(filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.pillBorder,
                    ),
                  ),
                  child: Text(
                    controller.categoryLabel(filter),
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.white : AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
