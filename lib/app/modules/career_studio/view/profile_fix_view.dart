import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/profile_report_controller.dart';
import '../service/career_ai_service.dart';
import '../widgets/career_widgets.dart';
import '../widgets/profile_draft_sheets.dart';
import 'profile_fixes_ready_view.dart';

/// "Fix this issue": what's wrong, the current text and a suggested rewrite
/// the user can accept, edit or swap. The suggestion is written by the AI.
class ProfileFixView extends StatefulWidget {
  const ProfileFixView({
    super.key,
    required this.controller,
    required this.fix,
    this.queue,
    this.index = 0,
  });

  final ProfileReportController controller;
  final ReportFix fix;

  /// "Fix all" mode: the fixes to walk through, and where we are. Null =
  /// a single fix opened from the report.
  final List<ReportFix>? queue;
  final int index;

  @override
  State<ProfileFixView> createState() => _ProfileFixViewState();
}

class _ProfileFixViewState extends State<ProfileFixView> {
  ProfileReportController get controller => widget.controller;
  ReportFix get fix => widget.fix;
  List<ReportFix>? get queue => widget.queue;
  int get index => widget.index;

  bool get _inQueue => queue != null;

  String get _current => controller.currentFor(fix, fix.nowKey.tr);
  String get _issue => fix.titleKey.tr;

  @override
  void initState() {
    super.initState();
    // After this frame: the call flips observables the build reads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _run(
        () => controller.loadSuggestion(fix, current: _current, issue: _issue),
      );
    });
  }

  /// Runs an AI call, showing its error (the screen stays usable).
  Future<void> _run(Future<void> Function() call) async {
    try {
      await call();
    } catch (e) {
      Get.snackbar(
        'career_ai_failed_title'.tr,
        e is GeminiException ? e.message : 'career_ai_error_generic'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  /// Opens the next fix in the queue, or "Fixes ready" after the last one.
  void _advance() {
    final q = queue;
    if (q == null) {
      Get.back();
      return;
    }
    if (index + 1 < q.length) {
      Get.off(
        () => ProfileFixView(
          controller: controller,
          fix: q[index + 1],
          queue: q,
          index: index + 1,
        ),
        routeName: '/ProfileFixView/${index + 1}',
        transition: Transition.rightToLeft,
      );
    } else if (controller.doneCount > 0) {
      Get.off(
        () => ProfileFixesReadyView(controller: controller),
        routeName: '/ProfileFixesReadyView',
        transition: Transition.rightToLeft,
      );
    } else {
      Get.back(); // everything skipped: nothing to review
    }
  }

  Future<void> _edit(BuildContext context, RxString text) async {
    final result = await showEditTextSheet(
      context,
      title: 'career_fix_edit_title'.tr,
      initial: text.value,
    );
    if (result != null && result.trim().isNotEmpty) text.value = result.trim();
  }

  Future<void> _tryAnother(BuildContext context, RxString text) async {
    if (!controller.canRewrite) {
      showNoRewritesSheet(context, onEditMyself: () => _edit(context, text));
      return;
    }
    await _run(
      () => controller.tryAnother(fix, current: _current, issue: _issue),
    );
  }

  void _use() {
    controller.markDone(fix);
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final text = controller.textFor(fix);
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: Column(
          children: [
            CareerAppBar(
              title: _inQueue
                  ? 'career_fix_queue_title'.trParams({
                      'n': index + 1,
                      'total': queue!.length,
                    })
                  : 'career_fix_title'.tr,
            ),
            if (_inQueue)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (index + 1) / queue!.length,
                    minHeight: 4,
                    backgroundColor: AppColors.profileStepInactive,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.onboardingBtnEnd,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          'career_fix_chip_impact'.trParams({
                            'impact': fix.impactKey.tr.toUpperCase(),
                          }),
                          filled: true,
                        ),
                        _Chip(
                          'career_fix_chip_points'.trParams({
                            'points': fix.points,
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fix.titleKey.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.titleDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fix.descKey.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSubtitle,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Heading('career_fix_now'.tr),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _current,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.textSubtitle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Heading('career_fix_suggested'.tr),
                        GestureDetector(
                          onTap: () => _edit(context, text),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              'career_fix_edit'.tr,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onboardingBtnEnd,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.onboardingBtnEnd,
                            width: 1.4,
                          ),
                        ),
                        child: controller.loading.contains(fix.id)
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.onboardingBtnEnd,
                                  ),
                                ),
                              )
                            : Text(
                                text.value.isEmpty
                                    ? 'career_fix_suggest_failed'.tr
                                    : text.value,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13.5,
                                  height: 1.45,
                                  color: AppColors.titleDark,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      // Read first so Obx always has something to observe.
                      final left = controller.rewritesLeft.value;
                      return Text(
                        controller.isPro
                            ? 'career_fix_rewrites_unlimited'.tr
                            : 'career_fix_rewrites_left'.trParams({
                                'count': left,
                              }),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.pillBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _OutlineButton(
                          label: 'career_fix_try_another'.tr,
                          onTap: () => _tryAnother(context, text),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Obx(
                          () => SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              // Nothing to accept until the suggestion exists.
                              onPressed:
                                  text.value.isEmpty ||
                                      controller.loading.contains(fix.id)
                                  ? null
                                  : _use,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.onboardingBtnEnd,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'career_fix_use_this'.tr,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_inQueue)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _advance,
                        child: Text(
                          'career_fix_skip'.tr,
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
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: AppColors.titleDark,
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.filled = false});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? AppColors.onboardingBtnEnd : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : AppColors.onboardingBtnEnd,
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.titleDark,
          side: const BorderSide(color: AppColors.pillBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
