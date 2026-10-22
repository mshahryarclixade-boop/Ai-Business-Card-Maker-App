import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/career_score_store.dart';
import '../controller/profile_report_controller.dart';
import '../widgets/career_widgets.dart';
import '../widgets/score_ring.dart';

/// "Your new score": before and after a Pro re-scan, with what each fix
/// added. Opening it saves the new score. UI only.
class ProfileNewScoreView extends StatefulWidget {
  const ProfileNewScoreView({super.key, this.save = true});

  /// Writes the re-scan result to [CareerScoreStore] (off in previews).
  final bool save;

  @override
  State<ProfileNewScoreView> createState() => _ProfileNewScoreViewState();
}

class _ProfileNewScoreViewState extends State<ProfileNewScoreView> {
  late final int _before = CareerScoreStore.base.value;
  late final List<ReportFix> _fixes = [
    for (final f in kReportFixes)
      if (CareerScoreStore.done.contains(f.id)) f,
  ];

  @override
  void initState() {
    super.initState();
    // Saved after this frame: changing observables the screens below are
    // watching must not happen while the tree is building.
    if (widget.save) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => CareerScoreStore.completeRescan(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gained = [for (final f in _fixes) f.points].fold(0, (a, b) => a + b);
    final after = _before + gained;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) CareerNav.toHub();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              CareerAppBar(
                title: 'career_newscore_title'.tr,
                leadingIcon: Icons.close_rounded,
                onLeading: CareerNav.toHub,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.pillBorder),
                        ),
                        child: Column(
                          children: [
                            ScoreBeforeAfter(
                              before: _before,
                              after: after,
                              beforeCaption: 'career_newscore_before'.tr,
                              afterCaption: 'career_newscore_now'.tr,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.onboardingBtnEnd,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'career_newscore_points'.trParams({
                                  'points': gained,
                                }),
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'career_newscore_saved'.tr,
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
                      const SizedBox(height: 14),
                      for (final f in _fixes) ...[
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.pillBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  f.nameKey.tr,
                                  style: const TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.titleDark,
                                  ),
                                ),
                              ),
                              Text(
                                '+${f.points}',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onboardingBtnEnd,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.pillBorder)),
                ),
                child: CareerPrimaryButton(
                  label: 'career_newscore_back'.tr,
                  onTap: CareerNav.toHub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
