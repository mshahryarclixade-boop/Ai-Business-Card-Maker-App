import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ScanToggleOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const ScanToggleOption({required this.value, required this.label, this.icon});
}

/// Dark, pill-shaped segmented control used on the Scan screen — for both
/// the Landscape/Portrait switch and the Card/QR Code switch.
class ScanSegmentedToggle<T> extends StatelessWidget {
  final List<ScanToggleOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const ScanSegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            _buildSegment(option, option.value == selected),
        ],
      ),
    );
  }

  Widget _buildSegment(ScanToggleOption<T> option, bool isSelected) {
    return GestureDetector(
      onTap: () => onChanged(option.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null) ...[
              Icon(
                option.icon,
                size: 14,
                color: isSelected ? AppColors.white : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              option.label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
