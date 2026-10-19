import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../paywall/view/paywall_screen.dart';
import '../widgets/career_widgets.dart';
import '../../../core/translations/tr_extension.dart';

/// Profile analysis report. UI only, dummy data.
class ProfileReportView extends StatelessWidget {
  const ProfileReportView({super.key});

  static const _scores = [
    ('career_report_score_headline', 30),
    ('career_report_score_about', 40),
    ('career_report_score_experience', 78),
    ('career_report_score_skills', 62),
    ('career_report_score_photo', 60),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: Column(
          children: [
            CareerAppBar(title: 'career_report_title'.tr),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ScoreCard(),
                    const SizedBox(height: 12),
                    _Box(
                      child: Column(
                        children: [
                          for (int i = 0; i < _scores.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _ScoreRow(_scores[i].$1, _scores[i].$2),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'career_report_top_fixes'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.titleDark,
                          ),
                        ),
                        Text(
                          'career_report_sorted_by_impact'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _HeadlineFix(),
                    const SizedBox(height: 8),
                    _Box(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'career_report_fix_about_title'.tr,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.titleDark,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'career_report_fix_about_description'.tr,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const _Badge('career_report_badge_high', filled: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => openPaywall(source: 'career', plans: true),
                  icon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: AppColors.crownGold,
                  ),
                  label: Text(
                    'career_report_fix_all_button'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

class _Box extends StatelessWidget {
  const _Box({required this.child, this.selected = false});

  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.onboardingBtnEnd : AppColors.pillBorder,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: child,
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard();

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Row(
        children: [
          SizedBox(
            width: 95,
            height: 95,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 85,
                  height: 85,
                  child: CircularProgressIndicator(
                    value: 0.54,
                    strokeWidth: 10,
                    backgroundColor: AppColors.profileStepInactive,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.onboardingBtnEnd,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '54',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 26,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.titleDark,
                      ),
                    ),
                    Text(
                      'career_report_score_of'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5E6888),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'career_report_needs_work'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'career_report_summary'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label.tr,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
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
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? AppColors.onboardingBtnEnd : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.tr,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : AppColors.onboardingBtnEnd,
        ),
      ),
    );
  }
}

class _HeadlineFix extends StatelessWidget {
  const _HeadlineFix();

  @override
  Widget build(BuildContext context) {
    return _Box(
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'career_report_headline_fix_title'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const _Badge('career_report_badge_high', filled: true),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSubtitle,
              ),
              children: [
                TextSpan(
                  text: 'career_report_now'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleDark,
                  ),
                ),
                TextSpan(text: 'career_report_now_value'.tr),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                  color: AppColors.titleDark,
                ),
                children: [
                  TextSpan(
                    text: 'career_report_suggested'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: 'career_report_suggested_value'.tr),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _FixButton('career_report_use_this', filled: true)),
              const SizedBox(width: 10),
              Expanded(child: _FixButton('career_report_try_another', filled: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FixButton extends StatelessWidget {
  const _FixButton(this.label, {required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: careerComingSoon,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? AppColors.onboardingBtnEnd : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: filled ? Colors.transparent : AppColors.pillBorder,
            ),
          ),
        ),
        child: Text(
          label.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : AppColors.titleDark,
          ),
        ),
      ),
    );
  }
}
