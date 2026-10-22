import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import 'career_widgets.dart';

/// "Get your profile as a PDF": how to export the profile before choosing
/// the file. [onChooseFile] runs after the sheet closes.
Future<void> showPdfHelpSheet(
  BuildContext context, {
  required VoidCallback onChooseFile,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'career_pdf_sheet_title'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 14),
            _Step(1, 'career_pdf_step_1'.tr),
            _Step(2, 'career_pdf_step_2'.tr),
            _Step(3, 'career_pdf_step_3'.tr),
            const SizedBox(height: 6),
            CareerPrimaryButton(
              label: 'career_pdf_choose_file'.tr,
              onTap: () {
                Navigator.of(ctx).pop();
                onChooseFile();
              },
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'career_pdf_cancel'.tr,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onboardingBtnEnd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.text);
  final int n;
  final String text;

  /// Renders `**bold**` markers as bold text.
  List<InlineSpan> _spans() {
    final out = <InlineSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      out.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.titleDark,
                )
              : null,
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: Text(
              '$n',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.onboardingBtnEnd,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 3),
              child: Text.rich(
                TextSpan(children: _spans()),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
