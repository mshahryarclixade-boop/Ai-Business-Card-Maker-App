import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/profile_report_controller.dart';
import '../widgets/career_hub_sheets.dart';
import '../widgets/career_widgets.dart';
import '../widgets/score_breakdown_sheet.dart';
import '../widgets/score_ring.dart';
import 'profile_fix_view.dart';
import 'profile_fixes_ready_view.dart';

/// Profile report: score, the fixes sorted by impact, and (from the top-right
/// icon) the score breakdown. UI only, dummy data.
class ProfileReportView extends StatefulWidget {
  const ProfileReportView({
    super.key,
    this.isPro,
    this.rewritesLeft,
    this.done = const {},
  });

  /// Pin Free/Pro, the rewrites left and the fixes already done
  /// (previews/tests); by default the subscription decides.
  final bool? isPro;
  final int? rewritesLeft;
  final Set<String> done;

  @override
  State<ProfileReportView> createState() => _ProfileReportViewState();
}

class _ProfileReportViewState extends State<ProfileReportView> {
  late final ProfileReportController _c;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = 'report_${identityHashCode(this)}';
    _c = Get.put(
      ProfileReportController(
        isPro: widget.isPro,
        rewritesLeft:
            widget.rewritesLeft ?? ProfileReportController.freeRewrites,
        done: widget.done,
        // A live report shares its score and fixes with the hub.
        persist: widget.isPro == null && widget.done.isEmpty,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<ProfileReportController>(tag: _tag);
    super.dispose();
  }

  /// The "Fix all 7 with Pro" button opens the Career Studio premium sheet.
  void _showPremium() => showUpgradeSheet(
    context,
    continueLabel: 'career_pro_continue_fixes'.tr,
    onUnlocked: () {
      final f = _c.next;
      if (f != null) _openFix(f);
    },
  );

  /// "Fix all": walk through every fix still open, one after another.
  void _startQueue() {
    final todo = _c.todo;
    if (todo.isEmpty) return;
    Get.to(
      () => ProfileFixView(controller: _c, fix: todo.first, queue: todo),
      routeName: '/ProfileFixView/0',
      transition: Transition.rightToLeft,
    );
  }

  void _seeFixes() => Get.to(
    () => ProfileFixesReadyView(controller: _c),
    routeName: '/ProfileFixesReadyView',
    transition: Transition.rightToLeft,
  );

  void _openFix(ReportFix f) {
    if (_c.isLocked(f)) {
      // CS31: upgrade from a locked fix, then carry on with that fix.
      showUpgradeSheet(
        context,
        lockedFeature: f.nameKey.tr,
        continueLabel: 'career_pro_continue_fixes'.tr,
        onUnlocked: () => _openFix(f),
      );
      return;
    }
    Get.to(
      () => ProfileFixView(controller: _c, fix: f),
      routeName: '/ProfileFixView/single',
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back (arrow or system) goes straight to Career Studio.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) CareerNav.toHub();
      },
      child: Scaffold(
        backgroundColor: AppColors.splashBg,
        body: SafeArea(
          child: Obx(() {
            // Touch the observables so this rebuilds as fixes get done.
            final doneCount = _c.done.length;
            _c.rewritesLeft.value;
            final next = _c.next;
            return Column(
              children: [
                CareerAppBar(
                  title: 'career_report_title'.tr,
                  onLeading: CareerNav.toHub,
                  trailing: GestureDetector(
                    onTap: () => showScoreBreakdownSheet(context),
                    behavior: HitTestBehavior.opaque,
                    child: Tooltip(
                      message: 'career_report_breakdown_tooltip'.tr,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.bar_chart_rounded,
                          size: 22,
                          color: AppColors.titleDark,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      4,
                      20,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ScoreCard(controller: _c),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'career_report_fixes_progress'.trParams({
                                  'done': doneCount,
                                  'total': _c.total,
                                }),
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.titleDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'career_report_by_impact'.tr,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11.5,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final f in kReportFixes) ...[
                          _FixRow(
                            fix: f,
                            done: _c.done.contains(f.id),
                            locked: _c.isLocked(f),
                            onTap: () => _openFix(f),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
                _BottomBar(
                  controller: _c,
                  next: next,
                  onFix: (_) => _startQueue(),
                  onSeeFixes: _seeFixes,
                  onUpgrade: _showPremium,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.controller});
  final ProfileReportController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final improved = c.doneCount > 0;
    final ring = c.ringScore;
    // Label and wording follow the score, so the report and the Career Studio
    // hub tell the same story.
    final (labelKey, bg, fg) = ring >= 80
        ? (
            'career_report_good',
            const Color(0xFFDDF5E3),
            const Color(0xFF1E6B3A),
          )
        : ring >= 60
        ? (
            'career_report_getting_there',
            AppColors.primarySoft,
            AppColors.onboardingBtnEnd,
          )
        : (
            'career_report_needs_work',
            const Color(0xFFFFF1C7),
            const Color(0xFF8A6100),
          );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pillBorder),
      ),
      child: Row(
        children: [
          ScoreRing(
            score: ring,
            size: 88,
            caption: 'career_report_score_of'.tr,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    labelKey.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (ring >= 80
                          ? 'career_report_summary_good'
                          : 'career_report_summary')
                      .tr,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textSubtitle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  improved
                      ? 'career_report_with_fixes'.trParams({'score': c.score})
                      : 'career_report_could_take_you'.trParams({
                          'score': c.potential,
                        }),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onboardingBtnEnd,
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

class _FixRow extends StatelessWidget {
  const _FixRow({
    required this.fix,
    required this.done,
    required this.locked,
    required this.onTap,
  });

  final ReportFix fix;
  final bool done;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = 'career_fix_row_meta'.trParams({
      'impact': fix.impactKey.tr,
      'points': fix.points,
    });
    return GestureDetector(
      onTap: done ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: done ? AppColors.onboardingBtnEnd : AppColors.pillBorder,
            width: done ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _Leading(done: done, locked: locked),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fix.titleKey.tr,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (done)
              _Tag('career_report_done'.tr, bg: AppColors.primarySoft)
            else if (locked)
              _Tag(
                'career_report_pro_badge'.tr,
                bg: AppColors.primaryDark,
                dark: true,
              )
            else
              _Tag(
                'career_report_fix'.tr,
                bg: AppColors.onboardingBtnEnd,
                dark: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.done, required this.locked});
  final bool done;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.onboardingBtnEnd,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    }
    if (locked) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryDark,
        ),
        child: const Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: AppColors.crownGold,
        ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.dotInactive, width: 1.6),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.bg, this.dark = false});
  final String label;
  final Color bg;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : AppColors.onboardingBtnEnd,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.next,
    required this.onFix,
    required this.onSeeFixes,
    required this.onUpgrade,
  });

  final ProfileReportController controller;
  final ReportFix? next;
  final void Function(ReportFix) onFix;
  final VoidCallback onSeeFixes;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final buttons = <Widget>[];
    if (next == null && c.doneCount > 0) {
      // Everything open is done: review the fixes.
      buttons.add(
        CareerPrimaryButton(
          label: 'career_report_see_fixes'.tr,
          onTap: onSeeFixes,
        ),
      );
    }
    if (next != null) {
      buttons.add(
        CareerPrimaryButton(
          label: c.isPro
              ? 'career_report_fix_all_pro'.trParams({'count': c.todo.length})
              : 'career_report_fix_free'.trParams({'count': c.todo.length}),
          onTap: () => onFix(next!),
        ),
      );
    }
    if (!c.isPro && c.lockedCount > 0) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 10));
      buttons.add(
        _DarkButton(
          label: c.doneCount == 0
              ? 'career_report_fix_all_with_pro'.trParams({'count': c.total})
              : 'career_report_unlock_more'.trParams({'count': c.lockedCount}),
          onTap: onUpgrade,
        ),
      );
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.pillBorder)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: AppColors.crownGold,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
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
