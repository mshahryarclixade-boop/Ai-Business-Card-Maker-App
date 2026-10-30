import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../career_studio/view/career_studio_view.dart';
import '../../clixa/widgets/clixa_avatars.dart';
import '../../expert_panel/view/expert_panel_view.dart';
import '../../../core/translations/tr_extension.dart';

/// "Your Business ToolKit" on Home: Career Studio and the Expert Panel.
/// UI and navigation only.
class AiToolkitSection extends StatelessWidget {
  const AiToolkitSection({super.key});

  void _open(Widget page) =>
      Get.to(() => page, transition: Transition.rightToLeft);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home_toolkit_heading'.tr,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.titleDark,
          ),
        ),
        const SizedBox(height: 8),
        _ToolkitCard(
          onTap: () => _open(const CareerStudioView()),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Image.asset(
                  'assets/images/toolkit/career.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          title: 'home_toolkit_career_studio_title',
          subtitle: 'home_toolkit_career_studio_subtitle',
        ),
        const SizedBox(height: 8),
        const _ExpertPanelCard(),
      ],
    );
  }
}

class _ToolkitCard extends StatelessWidget {
  const _ToolkitCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pillBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 62,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: leading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titleDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Expert Panel: five AI experts you can pitch an idea to (a Pro feature
/// later; free for now). UI only.
class _ExpertPanelCard extends StatelessWidget {
  const _ExpertPanelCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        // TODO: Pro only (showClixaUpgrade for free users). Open to
        // everyone while the panel is being tested.
        onTap: openExpertPanel,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.fromSTEB(14, 16, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.pillBorder, width: 1.5),
          ),
          child: Row(
            children: [
              const ExpertAvatars(size: 34, overlap: 8, count: 2),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'home_toolkit_expert_title'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.titleDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'clixa_pro'.tr,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.crownGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'home_toolkit_expert_subtitle'.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        height: 1.3,
                        color: AppColors.textSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
