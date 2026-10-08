import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LabeledField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final int maxLines;
  final FocusNode? focusNode;

  final TextCapitalization textCapitalization;

  final bool forceErrorBorder;

  const LabeledField({
    super.key,
    this.label,
    this.hint,
    required this.controller,
    this.icon,
    this.keyboardType,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.forceErrorBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
    forceErrorBorder ? Colors.red : AppColors.primary.withOpacity(0.28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.contactsTitleDark,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          validator: validator,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.contactsTitleDark,
          ),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.contactsSubtitleGrey,
            ),
            prefixIcon: icon != null
                ? Icon(
              icon,
              size: 18,
              color: AppColors.contactsSubtitleGrey,
            )
                : null,
            prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 0),
            filled: true,
            fillColor: AppColors.contactsLavenderBg.withOpacity(0.28),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: forceErrorBorder ? Colors.red : AppColors.primary,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}