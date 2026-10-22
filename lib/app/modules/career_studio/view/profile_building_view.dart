import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/generated_profile_store.dart';
import '../controller/profile_builder_flow_controller.dart';
import '../controller/profile_draft_controller.dart';
import '../service/career_ai_service.dart';
import 'profile_draft_view.dart';

/// "Writing your profile": progress checklist shown while the profile is
/// generated. The AI writes the profile from the builder's answers; the first
/// steps tick over on a timer and the last one completes with the result,
/// then the draft opens.
class ProfileBuildingView extends StatefulWidget {
  const ProfileBuildingView({super.key, this.isPro, this.stepDelay});

  final bool? isPro;

  /// Time per checklist step (shortened in tests).
  final Duration? stepDelay;

  @override
  State<ProfileBuildingView> createState() => _ProfileBuildingViewState();
}

class _ProfileBuildingViewState extends State<ProfileBuildingView> {
  int _done = 0; // checklist items finished (0-3)
  Timer? _timer;
  Timer? _minTimer;

  @override
  void initState() {
    super.initState();
    final delay = widget.stepDelay ?? const Duration(milliseconds: 1100);
    _timer = Timer.periodic(delay, (t) {
      if (!mounted) return;
      if (_done < 2) setState(() => _done++);
    });
    _generate(delay * 2);
  }

  Future<void> _generate(Duration minimum) async {
    final wait = Completer<void>();
    _minTimer = Timer(minimum, wait.complete); // cancelled in dispose
    try {
      final flow = Get.isRegistered<ProfileBuilderFlowController>()
          ? Get.find<ProfileBuilderFlowController>()
          : null;
      final texts = await CareerAi.instance.buildProfile(
        flow?.toAnswers() ?? const {},
      );
      await wait.future;
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _done = 3);
      GeneratedProfileStore.save(texts, ProfileDraftController.freeRewrites);
      Get.off(
        () => ProfileDraftView(isPro: widget.isPro, initial: texts),
        transition: Transition.rightToLeft,
      );
    } catch (e) {
      if (!mounted) return;
      // Nothing was generated: back to the builder, answers kept.
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
    _minTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'career_building_step_reading'.tr,
      'career_building_step_keywords'.tr,
      'career_building_step_writing'.tr,
    ];
    return PopScope(
      canPop: false, // Cancel is the way out.
      child: Scaffold(
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
                    'career_building_title'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < steps.length; i++)
                    _StepRow(text: steps[i], done: i < _done),
                  const SizedBox(height: 10),
                  Text(
                    'career_building_takes'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'career_building_cancel'.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onboardingBtnEnd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.text, required this.done});
  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.onboardingBtnEnd,
                  )
                : Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.onboardingBtnEnd,
                        width: 1.4,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: AppColors.titleDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
