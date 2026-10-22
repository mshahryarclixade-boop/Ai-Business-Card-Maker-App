import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/career_hub_controller.dart';
import '../controller/career_score_store.dart';
import '../controller/profile_report_controller.dart';
import '../widgets/career_hub_sheets.dart';
import '../widgets/career_widgets.dart';
import '../widgets/score_ring.dart';
import 'profile_analyzing_view.dart';
import 'profile_fix_view.dart';

/// "Fixes ready": the accepted fixes and the score they should give. Pro
/// users go on to re-scan; Free users save the fixes and re-scan when their
/// free scan renews. UI only.
class ProfileFixesReadyView extends StatelessWidget {
  const ProfileFixesReadyView({super.key, required this.controller});

  final ProfileReportController controller;

  List<ReportFix> get _done => [
    for (final f in kReportFixes)
      if (controller.done.contains(f.id)) f,
  ];

  void _rescan() => Get.to(
    () => const ProfileAnalyzingView(rescan: true),
    routeName: '/ProfileRescan',
    transition: Transition.rightToLeft,
  );

  void _save() {
    if (controller.persist) CareerScoreStore.saveFixes();
    final date = CareerHubState.nextResetDate();
    CareerNav.toHub();
    Get.snackbar(
      'career_ready_saved_title'.tr,
      'career_ready_saved_message'.trParams({'date': date}),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
  }

  /// Free user unlocks Pro here: carry on with the rest of the fixes.
  void _startRemaining() {
    final todo = controller.todo;
    if (todo.isEmpty) return;
    Get.off(
      () => ProfileFixView(
        controller: controller,
        fix: todo.first,
        queue: todo,
      ),
      routeName: '/ProfileFixView/0',
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Obx(() {
          final done = _done;
          final locked = [
            for (final f in kReportFixes)
              if (c.isLocked(f) && !c.done.contains(f.id)) f,
          ];
          final isPro = c.isPro;
          return Column(
            children: [
              CareerAppBar(title: 'career_ready_title'.tr),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: _box(),
                        child: ScoreBeforeAfter(
                          before: c.scanScore,
                          after: c.score,
                          afterCaption: 'career_ready_expected'.tr,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'career_ready_count'.trParams({'count': done.length}),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.titleDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final f in done) ...[
                        _ReadyRow(fix: f),
                        const SizedBox(height: 8),
                      ],
                      if (!isPro && locked.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _UpsellCard(
                          locked: locked,
                          potential: c.potential,
                          onUnlock: () => showUpgradeSheet(
                            context,
                            continueLabel: 'career_pro_continue_fixes'.tr,
                            onUnlocked: _startRemaining,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.pillBorder)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CareerPrimaryButton(
                      label: isPro
                          ? 'career_ready_rescan'.tr
                          : 'career_ready_save'.tr,
                      onTap: isPro ? _rescan : _save,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'career_ready_back'.tr,
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
          );
        }),
      ),
    );
  }
}

BoxDecoration _box() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.pillBorder),
);

class _ReadyRow extends StatelessWidget {
  const _ReadyRow({required this.fix});
  final ReportFix fix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.pillBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_rounded,
            size: 16,
            color: AppColors.onboardingBtnEnd,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fix.titleKey.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.titleDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${fix.points}',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpsellCard extends StatelessWidget {
  const _UpsellCard({
    required this.locked,
    required this.potential,
    required this.onUnlock,
  });

  final List<ReportFix> locked;
  final int potential;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final names = locked.map((f) => f.nameKey.tr).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'career_ready_upsell_title'.trParams({
              'count': locked.length,
              'score': potential,
            }),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'career_ready_upsell_message'.trParams({'names': names.join(', ')}),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11.5,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7D486),
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'career_ready_unlock'.tr,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
