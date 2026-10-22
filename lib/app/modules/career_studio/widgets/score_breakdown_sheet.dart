import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/translations/tr_extension.dart';
import '../controller/career_score_store.dart';

/// Placeholder scores, shown only when no scan result is saved.
const _scores = [
  ('career_report_score_headline', 30),
  ('career_report_score_about', 40),
  ('career_report_score_experience', 78),
  ('career_report_score_skills', 62),
  ('career_report_score_photo', 60),
  ('career_report_score_featured', 0),
  ('career_report_score_link', 50),
];

/// "Score breakdown" popup, opened from the report's top-right icon.
Future<void> showScoreBreakdownSheet(BuildContext context) {
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
              'career_report_breakdown_title'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'career_report_breakdown_subtitle'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.textSubtitle,
              ),
            ),
            const SizedBox(height: 16),
            // The last scan's scores, raised by the fixes accepted since.
            Obx(() {
              CareerScoreStore.done.length; // re-draw when a fix is accepted
              final scanned = CareerScoreStore.partScores.isNotEmpty;
              return Column(
                children: [
                  for (final s in _scores)
                    _ScoreRow(
                      s.$1,
                      scanned
                          ? CareerScoreStore.partScore(
                              s.$1.replaceFirst('career_report_score_', ''),
                            )
                          : s.$2,
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.titleDark,
                  side: const BorderSide(color: AppColors.pillBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'career_report_breakdown_close'.tr,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.labelKey, this.value);
  final String labelKey;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              labelKey.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.titleDark,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 5,
                backgroundColor: AppColors.profileStepInactive,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.onboardingBtnEnd,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.titleDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
