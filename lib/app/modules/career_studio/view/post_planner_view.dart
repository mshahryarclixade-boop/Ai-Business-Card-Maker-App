import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/career_widgets.dart';
import '../../../core/translations/tr_extension.dart';

/// Post Planner teaser. UI only, dummy data.
class PostPlannerView extends StatelessWidget {
  const PostPlannerView({super.key});

  static const _days = [
    'career_post_planner_day_mon',
    'career_post_planner_day_tue',
    'career_post_planner_day_wed',
    'career_post_planner_day_thu',
    'career_post_planner_day_fri',
    'career_post_planner_day_sat',
    'career_post_planner_day_sun',
  ];
  static const _perks = [
    'career_post_planner_perk_writer',
    'career_post_planner_perk_calendar',
    'career_post_planner_perk_insights',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CareerAppBar(title: 'career_post_planner_title'.tr),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Calendar(days: _days),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'career_post_planner_coming_soon'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'career_post_planner_heading'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.titleDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final p in _perks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AppColors.onboardingBtnEnd,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.tr,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.titleDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: CareerPrimaryButton(
                label: 'career_post_planner_notify_button'.tr,
                onTap: careerComingSoon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.days});

  final List<String> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final d in days)
                Expanded(
                  child: Center(
                    child: Text(
                      d.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSubtitle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < days.length; i++)
                Expanded(
                  child: Container(
                    height: 40,
                    margin: EdgeInsetsDirectional.only(end: i == days.length - 1 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: i == 1
                          ? AppColors.onboardingBtnEnd
                          : i == 3
                          ? AppColors.onboardingBtnEnd
                          .withValues(alpha: 0.4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'career_post_planner_sample_time_1'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onboardingBtnEnd,
                      ),
                    ),
                    _StatusTag('career_post_planner_status_scheduled'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'career_post_planner_sample_title_1'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
                const SizedBox(height: 10),
                _Line(widthFactor: 0.95),
                const SizedBox(height: 6),
                _Line(widthFactor: 0.6),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'career_post_planner_sample_time_2'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color:
                        AppColors.onboardingBtnEnd.withValues(alpha: 0.7),
                      ),
                    ),
                    _StatusTag('career_post_planner_status_draft'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'career_post_planner_sample_title_2'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
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

class _StatusTag extends StatelessWidget {
  const _StatusTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.tr,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSubtitle,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.profileStepInactive,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}