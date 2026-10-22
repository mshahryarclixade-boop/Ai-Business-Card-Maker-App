import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/profile_builder_flow_controller.dart';
import '../controller/profile_draft_controller.dart';
import '../service/career_ai_service.dart';
import '../widgets/career_widgets.dart';
import '../widgets/profile_draft_sheets.dart';

/// "Your new profile": the generated Headline, About and Experience, each
/// with Copy, Edit and Rewrite. The texts come from the AI ([initial]);
/// Rewrite asks it for new wording of the same facts.
class ProfileDraftView extends StatefulWidget {
  const ProfileDraftView({
    super.key,
    this.isPro,
    this.rewritesLeft,
    this.initial,
  });

  /// The generated profile. Null (previews/tests) shows sample text.
  final ProfileDraftTexts? initial;

  /// Pin Free/Pro and the rewrites left (previews/tests); by default the
  /// subscription decides and Free starts with 3.
  final bool? isPro;
  final int? rewritesLeft;

  @override
  State<ProfileDraftView> createState() => _ProfileDraftViewState();
}

class _ProfileDraftViewState extends State<ProfileDraftView> {
  late final ProfileDraftController _c;
  late final String _tag;

  @override
  void initState() {
    super.initState();
    _tag = 'draft_${identityHashCode(this)}';
    _c = Get.put(
      ProfileDraftController(
        isPro: widget.isPro,
        rewritesLeft:
            widget.rewritesLeft ?? ProfileDraftController.freeRewrites,
        persist: widget.initial != null,
      ),
      tag: _tag,
    );

    final i = widget.initial;
    if (i != null) {
      _c.load({
        DraftSection.headline: i.headline,
        DraftSection.about: i.about,
        DraftSection.experience: i.experience,
      });
    } else {
      final params = {
        'role': 'career_draft_sample_role'.tr,
        'company': 'career_draft_sample_company'.tr,
      };
      _c.load({
        DraftSection.headline: 'career_draft_headline_1'.trParams(params),
        DraftSection.about: 'career_draft_about_1'.tr,
        DraftSection.experience: 'career_draft_experience_1'.trParams(params),
      });
    }
  }

  late final ProfileBuilderFlowController? _flow =
      Get.isRegistered<ProfileBuilderFlowController>()
      ? Get.find<ProfileBuilderFlowController>()
      : null;

  @override
  void dispose() {
    Get.delete<ProfileDraftController>(tag: _tag);
    super.dispose();
  }

  String _titleOf(DraftSection s) => switch (s) {
    DraftSection.headline => 'career_draft_headline'.tr,
    DraftSection.about => 'career_draft_about'.tr,
    DraftSection.experience => 'career_draft_experience'.tr,
  };

  String _editTitleOf(DraftSection s) => switch (s) {
    DraftSection.headline => 'career_draft_edit_headline'.tr,
    DraftSection.about => 'career_draft_edit_about'.tr,
    DraftSection.experience => 'career_draft_edit_experience'.tr,
  };

  Future<void> _copy(DraftSection s) async {
    await Clipboard.setData(ClipboardData(text: _c.texts[s]!.value));
    Get.snackbar(
      'career_draft_copied_title'.tr,
      'career_draft_copied_message'.trParams({'section': _titleOf(s)}),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _edit(DraftSection s) async {
    final text = await showEditTextSheet(
      context,
      title: _editTitleOf(s),
      initial: _c.texts[s]!.value,
    );
    if (text != null && text.trim().isNotEmpty) _c.setText(s, text);
  }

  Future<void> _rewrite(DraftSection s) async {
    if (!_c.canRewrite) {
      showNoRewritesSheet(context, onEditMyself: () => _edit(s));
      return;
    }
    try {
      await _c.rewrite(
        s,
        (current) => CareerAi.instance.rewrite(
          section: s.name,
          text: current,
          answers: _flow?.toAnswers(),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'career_ai_failed_title'.tr,
        e is GeminiException ? e.message : 'career_ai_error_generic'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
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
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              Obx(() {
                // Read first so Obx always has something to observe (Pro never
                // shows the count).
                final left = _c.rewritesLeft.value;
                return CareerAppBar(
                  title: 'career_draft_title'.tr,
                  onLeading: CareerNav.toHub,
                  trailing: _RewritesPill(
                    label: _c.isPro
                        ? 'career_draft_rewrites_unlimited'.tr
                        : 'career_draft_rewrites_left'.trParams({
                            'count': left,
                          }),
                  ),
                );
              }),
              const Divider(height: 1, color: AppColors.pillBorder),
              Expanded(
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 24),
                  children: [
                    for (final s in DraftSection.values) ...[
                      Obx(
                        () => _SectionCard(
                          title: _titleOf(s),
                          text: _c.texts[s]!.value,
                          rewriting: _c.busy.contains(s),
                          onCopy: () => _copy(s),
                          onEdit: () => _edit(s),
                          onRewrite: () => _rewrite(s),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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

class _RewritesPill extends StatelessWidget {
  const _RewritesPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: AppColors.onboardingBtnEnd,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.text,
    required this.onCopy,
    required this.onEdit,
    required this.onRewrite,
    this.rewriting = false,
  });

  final bool rewriting;

  final String title;
  final String text;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onRewrite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pillBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onCopy,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'career_draft_copy'.tr,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onboardingBtnEnd,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'career_draft_edit'.tr,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'career_draft_rewrite'.tr,
                  icon: Icons.auto_awesome,
                  accent: true,
                  loading: rewriting,
                  onTap: onRewrite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.accent = false,
    this.loading = false,
  });

  final bool loading;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.onboardingBtnEnd : AppColors.titleDark;
    return SizedBox(
      height: 38,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: loading ? null : onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.pillBorder),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    ),
                  if (loading)
                    const SizedBox(width: 6)
                  else if (icon != null) ...[
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: color,
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
