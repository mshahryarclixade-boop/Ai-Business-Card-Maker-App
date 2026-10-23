import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../../core/widgets/crown_upgrade_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../controller/career_hub_controller.dart';
import '../controller/career_score_store.dart';
import '../controller/generated_profile_store.dart';
import '../controller/profile_builder_flow_controller.dart';
import '../widgets/career_hub_sheets.dart';
import '../widgets/career_widgets.dart';
import 'profile_builder_view.dart';
import 'profile_draft_view.dart';
import 'profile_generated_view.dart';
import 'profile_optimizer_view.dart';
import 'profile_report_view.dart';

/// Career Studio hub: plan status, the tools (Profile Builder, Profile
/// Optimizer, Post Planner) and the hub popups, for Free, Pro and returning
/// users. UI only: usage numbers are placeholders until a backend exists.
class CareerStudioView extends StatefulWidget {
  /// [initial] pins the state shown (previews/tests); by default the hub
  /// follows the user's subscription.
  const CareerStudioView({super.key, this.initial});

  final CareerHubState? initial;

  @override
  State<CareerStudioView> createState() => _CareerStudioViewState();
}

class _CareerStudioViewState extends State<CareerStudioView> {
  late final CareerHubController _c;
  late final String _tag;
  String? _routeName;

  @override
  void initState() {
    super.initState();
    _tag = 'career_hub_${identityHashCode(this)}';
    _c = Get.put(CareerHubController(widget.initial), tag: _tag);
    if (widget.initial == null) _c.syncSubscription();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lets deeper screens (new profile, report) jump straight back here.
    _routeName = ModalRoute.of(context)?.settings.name;
    CareerNav.hubRoute = _routeName;
    ProfileBuilderDraftStore.load();
    CareerScoreStore.load();
    GeneratedProfileStore.load();
  }

  @override
  void dispose() {
    if (CareerNav.hubRoute == _routeName) CareerNav.hubRoute = null;
    Get.delete<CareerHubController>(tag: _tag);
    super.dispose();
  }

  /// GetX names an unnamed route after the type of the page *builder*, and
  /// `() => page` is always just `() => Widget`. Home opens this hub the same
  /// way, so without an explicit name GetX treats every tap here as a
  /// duplicate of the current route and silently does nothing.
  void _open(Widget page) => Get.to(
    () => page,
    routeName: '/${page.runtimeType}',
    transition: Transition.rightToLeft,
  );

  void _openBuilder(CareerHubState s) {
    if (s.buildUsed && GeneratedProfileStore.built.value) {
      // Free build already used: go straight to the profile it made.
      _open(
        ProfileDraftView(
          initial: GeneratedProfileStore.texts,
          rewritesLeft: GeneratedProfileStore.rewritesLeft,
        ),
      );
    } else if (s.buildUsed) {
      showBuildUsedSheet(
        context,
        resetDate: s.resetDate,
        onOpenDraft: s.hasDraft ? _openDraft : null,
      );
    } else {
      _open(const ProfileBuilderView());
    }
  }

  void _openOptimizer(CareerHubState s) {
    if (s.scanUsed) {
      showScanUsedSheet(
        context,
        resetDate: s.resetDate,
        onOpenReport: s.hasReport ? _openReport : null,
      );
    } else {
      _open(const ProfileOptimizerView());
    }
  }

  void _resumeBuilder() => _open(const ProfileBuilderView(resume: true));

  void _openDraft() => _open(ProfileGeneratedView(profileData: const {}));
  void _openReport() => _open(const ProfileReportView());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Obx(() {
          var s = _c.state.value;
          // Follow the live subscription unless a state is pinned.
          if (widget.initial == null &&
              Get.isRegistered<SubscriptionController>()) {
            final pro = Get.find<SubscriptionController>().isUserPro.value;
            if (pro != s.isPro) s = s.copyWith(isPro: pro);
          }
          // The free build is spent once a profile has been generated.
          if (widget.initial == null && GeneratedProfileStore.built.value) {
            s = s.copyWith(buildsLeft: s.isPro ? s.buildsLeft : 0);
          }
          // The score comes from the report (shared with the report screen);
          // a pinned state (previews/tests) shows what it was given.
          final live = widget.initial == null;
          final scanned = live && CareerScoreStore.scanned.value;
          if (scanned) {
            s = s.copyWith(
              score: CareerScoreStore.current,
              fixesDone: CareerScoreStore.done.length,
              // The free scan is spent once a report exists.
              scansLeft: s.isPro ? s.scansLeft : 0,
            );
          }
          return Column(
            children: [
              CareerAppBar(
                title: 'career_hub_title'.tr,
                trailing: s.isPro
                    ? const _ProBadge()
                    : CrownUpgradeButton(
                  onTap: () => showUpgradeSheet(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(state: s),
                      const SizedBox(height: 12),
                      if (s.hasReport) ...[
                        _ScoreCard(
                          score: s.score!,
                          subtitle: _scoreSubtitle(s, scanned),
                          onTap: _openReport,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (ProfileBuilderDraftStore.hasDraft.value) ...[
                        _DraftCard(
                          title: 'career_hub_finish_title'.tr,
                          subtitle: 'career_hub_finish_subtitle'.trParams({
                            'step': ProfileBuilderDraftStore.step.value,
                          }),
                          onContinue: _resumeBuilder,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (s.hasDraft) ...[
                        _DraftCard(
                          title: 'career_hub_draft_title'.tr,
                          subtitle: 'career_hub_draft_subtitle'.tr,
                          onContinue: _openDraft,
                        ),
                        const SizedBox(height: 10),
                      ],
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: 6,
                          bottom: 10,
                        ),
                        child: Text(
                          'career_hub_tools_heading'.tr,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.titleDark,
                          ),
                        ),
                      ),
                      _ToolCard(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'career_hub_tool_builder_title'.tr,
                        description: 'career_hub_tool_builder_description'.tr,
                        badge: _badge(s, used: s.buildUsed),
                        onTap: () => _openBuilder(s),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.trending_up_rounded,
                        title: 'career_hub_tool_optimizer_title'.tr,
                        description: 'career_hub_tool_optimizer_description'.tr,
                        badge: _badge(s, used: s.scanUsed),
                        onTap: () => _openOptimizer(s),
                      ),
                      const SizedBox(height: 10),
                      _PostPlannerCard(
                        onTap: () => showPostPlannerSoonSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Second line of the score card: where the user is in the report.
  String _scoreSubtitle(CareerHubState s, bool live) {
    if (live) {
      if (CareerScoreStore.rescanned.value) {
        return 'career_hub_score_improved'.trParams({
          'before': CareerScoreStore.before.value,
        });
      }
      if (CareerScoreStore.fixesReady.value) {
        return 'career_hub_score_expected'.trParams({
          'expected': CareerScoreStore.expected,
          'date': s.resetDate,
        });
      }
    }
    return 'career_hub_score_subtitle'.trParams({
      'done': s.fixesDone,
      'total': s.fixesTotal,
    });
  }

  String _badge(CareerHubState s, {required bool used}) {
    if (s.isPro) return 'career_hub_badge_unlimited'.tr;
    return used ? 'career_hub_badge_used'.tr : 'career_hub_badge_free'.tr;
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'career_hub_pro_badge'.tr,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.crownGold,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});
  final CareerHubState state;

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    final s = state;
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'career_hub_hero_title'.tr,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  (s.isPro ? 'career_hub_hero_plan_pro' : 'career_hub_hero_plan_free').tr,
                  style: small,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  s.isPro
                      ? 'career_hub_hero_unlimited'.tr
                      : 'career_hub_hero_usage'.trParams({
                          'builds': s.buildsLeft,
                          'scans': s.scansLeft,
                        }),
                  textAlign: TextAlign.end,
                  style: small,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.isPro
                ? 'career_hub_hero_pro_note'.tr
                : 'career_hub_hero_free_note'.trParams({'date': s.resetDate}),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardBox({Color? border, double width = 1}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: border ?? AppColors.pillBorder, width: width),
);

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.subtitle,
    required this.onTap,
  });
  final int score;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
        decoration: _cardBox(),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 4,
                      backgroundColor: AppColors.progressTrack,
                      color: AppColors.onboardingBtnEnd,
                    ),
                  ),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'career_hub_score_title'.trParams({'score': score}),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.title,
    required this.subtitle,
    required this.onContinue,
  });
  final String title;
  final String subtitle;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 10, 10),
      decoration: _cardBox(border: AppColors.onboardingBtnEnd, width: 1.5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onContinue,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.onboardingBtnEnd,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'career_hub_continue'.tr,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.amber = false});
  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: amber ? const Color(0xFFFFF1C7) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: amber ? const Color(0xFF8A6100) : AppColors.onboardingBtnEnd,
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: AppColors.onboardingBtnEnd),
    );
  }
}

class _ToolBody extends StatelessWidget {
  const _ToolBody({
    required this.icon,
    required this.title,
    required this.description,
    required this.pill,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget pill;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconTile(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.titleDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  pill,
                ],
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textSubtitle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _cardBox(),
        child: _ToolBody(
          icon: icon,
          title: title,
          description: description,
          pill: _Pill(badge),
        ),
      ),
    );
  }
}

class _PostPlannerCard extends StatelessWidget {
  const _PostPlannerCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DashedBox(
        radius: 14,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          child: _ToolBody(
            icon: Icons.calendar_today_outlined,
            title: 'career_hub_post_planner_title'.tr,
            description: 'career_hub_post_planner_description'.tr,
            pill: _Pill('career_hub_coming_soon_badge'.tr, amber: true),
          ),
        ),
      ),
    );
  }
}
