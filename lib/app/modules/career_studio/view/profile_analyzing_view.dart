import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/career_score_store.dart';
import '../controller/profile_optimizer_controller.dart';
import '../service/career_ai_service.dart';
import 'profile_new_score_view.dart';
import 'profile_report_view.dart';

/// "Checking 7 parts of your profile": shown between the optimizer's
/// Analyze button and the report. A fresh scan has the AI analyze the profile
/// (at least [duration] on screen); a re-scan just waits a moment.
class ProfileAnalyzingView extends StatefulWidget {
  const ProfileAnalyzingView({super.key, this.duration, this.rescan = false});

  /// Re-scanning after the fixes (Pro): ends on "Your new score" instead of
  /// a fresh report.
  final bool rescan;

  /// How long to show it (shortened in tests).
  final Duration? duration;

  @override
  State<ProfileAnalyzingView> createState() => _ProfileAnalyzingViewState();
}

class _ProfileAnalyzingViewState extends State<ProfileAnalyzingView> {
  Timer? _timer;

  static const _parts = [
    'career_analyzing_part_headline',
    'career_analyzing_part_about',
    'career_analyzing_part_experience',
    'career_analyzing_part_skills',
    'career_analyzing_part_featured',
    'career_analyzing_part_banner',
    'career_analyzing_part_link',
  ];

  @override
  void initState() {
    super.initState();
    final wait = widget.duration ?? const Duration(milliseconds: 2800);
    if (widget.rescan) {
      _timer = Timer(wait, () {
        if (!mounted) return;
        Get.off(
          () => const ProfileNewScoreView(),
          routeName: '/ProfileNewScore',
          transition: Transition.rightToLeft,
        );
      });
    } else {
      _scan(wait);
    }
  }

  Future<void> _scan(Duration wait) async {
    final minimum = Completer<void>();
    _timer = Timer(wait, minimum.complete); // cancelled in dispose
    try {
      final input = Get.isRegistered<ProfileOptimizerController>()
          ? await Get.find<ProfileOptimizerController>().scanInput()
          : const ProfileScanInput();
      final analysis = await CareerAi.instance.analyze(input);
      await minimum.future;
      if (!mounted) return;
      CareerScoreStore.newScan(analysis); // a new scan starts a new report
      Get.off(
        () => const ProfileReportView(),
        transition: Transition.rightToLeft,
      );
    } catch (e) {
      if (!mounted) return;
      // Nothing was scanned: back to the optimizer to try again.
      Get.back();
      Get.snackbar(
        'career_ai_failed_title'.tr,
        e is GeminiException ? e.message : 'career_ai_error_generic'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 46,
                  height: 46,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: AppColors.onboardingBtnEnd,
                    backgroundColor: AppColors.progressTrack,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.rescan
                      ? 'career_rescan_title'.tr
                      : 'career_analyzing_title'.trParams({'count': 7}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in _parts)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.tr,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onboardingBtnEnd,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'career_analyzing_takes'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
