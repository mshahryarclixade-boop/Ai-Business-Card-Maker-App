import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

const _inputTextStyle = TextStyle(
  fontFamily: 'Inter',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 20 / 16,
  color: AppColors.splashTextPrimary,
);

const _hintTextStyle = TextStyle(
  fontFamily: 'Inter',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 20 / 16,
  color: AppColors.profileHintText,
);

class ProfileFieldShell extends StatelessWidget {
  const ProfileFieldShell({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
  });

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: 0,
            color: AppColors.splashTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        child,
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.profileError,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: BorderSide(color: color, width: 1),
);

class ProfileTextField extends StatelessWidget {
  const      ProfileTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textColor,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final borderColor =
    hasError ? AppColors.profileError : AppColors.profileFieldBorder;

    return ProfileFieldShell(
      label: label,
      errorText: errorText,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: _inputTextStyle.copyWith(color: textColor),
        cursorColor: AppColors.profileStepActive,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _hintTextStyle,
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: _border(borderColor),
          focusedBorder: _border(
            hasError ? AppColors.profileError : AppColors.profileStepActive,
          ),
          border: _border(borderColor),
        ),
      ),
    );
  }
}

class ProfilePhoneField extends StatelessWidget {
  const ProfilePhoneField({
    super.key,
    required this.controller,
    required this.initialDialCode,
    required this.onCountryChanged,
    this.errorText,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final String initialDialCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return ProfileFieldShell(
      label: 'Phone number',
      errorText: errorText,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasError
                ? AppColors.profileError
                : AppColors.profileFieldBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CountryCodePicker(
              onChanged: onCountryChanged,
              initialSelection: initialDialCode,
              showFlag: true,
              showDropDownButton: true,
              alignLeft: false,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: _inputTextStyle,
            ),
            Container(
              width: 1,
              height: 20,
              color: AppColors.profileFieldBorder,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onChanged: onChanged,
                style: _inputTextStyle,
                cursorColor: AppColors.profileStepActive,
                decoration: const InputDecoration(
                  hintText: '300 1234567',
                  hintStyle: _hintTextStyle,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}