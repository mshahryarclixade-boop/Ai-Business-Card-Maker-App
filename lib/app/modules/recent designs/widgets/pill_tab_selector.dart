import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/translations/tr_extension.dart';

/// Two-segment sliding pill selector used for "Saved | Favorite".
class PillTabSelector extends StatelessWidget {
  final int selectedIndex; // 0 or 1
  final List<String>? labels;
  final ValueChanged<int> onChanged;

  const PillTabSelector({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final labels = this.labels ??
        ['pill_tab_saved'.tr, 'pill_tab_favorite'.tr];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final bool selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textGrey,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}