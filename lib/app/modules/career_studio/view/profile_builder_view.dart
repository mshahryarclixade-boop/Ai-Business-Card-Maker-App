import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../controller/profile_builder_flow_controller.dart';
import '../widgets/career_widgets.dart';
import '../widgets/profile_builder_dialogs.dart';
import 'profile_building_view.dart';

/// Profile Builder: three steps (check details, goal and audience, tone and
/// wins), then the "Writing your profile" loading screen. UI only.
class ProfileBuilderView extends StatefulWidget {
  const ProfileBuilderView({super.key, this.isPro, this.resume = false});

  /// Pins Free/Pro (previews/tests); by default follows the subscription.
  final bool? isPro;

  /// Pick up an unfinished draft at the step the user left on.
  final bool resume;

  @override
  State<ProfileBuilderView> createState() => _ProfileBuilderViewState();
}

class _ProfileBuilderViewState extends State<ProfileBuilderView> {
  late final ProfileBuilderFlowController _c;

  final _roleFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _locationFocus = FocusNode();

  static const _goalKeys = kCareerGoalKeys;

  static const _audienceKeys = {
    'Startup founders': 'career_builder_audience_founders',
    'Recruiters': 'career_builder_audience_recruiters',
    'Product managers': 'career_builder_audience_pms',
    'Agencies': 'career_builder_audience_agencies',
    'Investors': 'career_builder_audience_investors',
    'Small businesses': 'career_builder_audience_small_biz',
  };

  static const _toneKeys = {
    'Professional': 'career_builder_tone_professional',
    'Friendly': 'career_builder_tone_friendly',
    'Bold': 'career_builder_tone_bold',
  };

  static const _bandKeys = {
    '0-2': 'career_builder_exp_0_2',
    '3-5': 'career_builder_exp_3_5',
    '6-10': 'career_builder_exp_6_10',
    '10+': 'career_builder_exp_10_plus',
  };

  bool get _isPro =>
      widget.isPro ??
          (Get.isRegistered<SubscriptionController>() &&
              Get.find<SubscriptionController>().isUserPro.value);

  @override
  void initState() {
    super.initState();
    // Permanent so answers survive leaving and coming back.
    _c = Get.isRegistered<ProfileBuilderFlowController>()
        ? Get.find<ProfileBuilderFlowController>()
        : Get.put(ProfileBuilderFlowController(), permanent: true);
    final draft = widget.resume ? ProfileBuilderDraftStore.load() : null;
    if (draft != null) {
      _c.applyDraft(draft);
      _c.step.value = ((draft['step'] as num?)?.toInt() ?? 1).clamp(1, 3);
    } else {
      _c.step.value = 1;
      _c.prefillFromCard();
    }
  }

  @override
  void dispose() {
    _roleFocus.dispose();
    _companyFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    final leave = await showLeaveBuilderDialog(context);
    if (leave == true && mounted) {
      // "Your answers are saved": keep them as a draft to resume from the hub.
      _c.saveDraftIfStarted();
      Navigator.of(context).pop();
    }
  }

  void _generate() {
    ProfileBuilderDraftStore.clear(); // finished: nothing left to resume
    Get.to(
          () => ProfileBuildingView(isPro: widget.isPro),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = _c.step.value;
      return PopScope(
        // System back always asks first, like the close button.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          backgroundColor: AppColors.splashBg,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Column(
                children: [
                  CareerAppBar(
                    title: 'career_builder_title'.tr,
                    leadingIcon: step == 1
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                    onLeading: step == 1 ? _leave : _c.back,
                    trailing: Text(
                      'career_builder_step_of'.trParams({
                        'step': step,
                        'total': 3,
                      }),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 20,
                    ),
                    child: _StepBar(step: step, total: 3),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        22,
                        20,
                        16,
                      ),
                      child: switch (step) {
                        1 => _stepDetails(),
                        2 => _stepAudience(),
                        _ => _stepTone(),
                      },
                    ),
                  ),
                  _Footer(
                    note: step == 3 && !_isPro
                        ? 'career_builder_free_build_note'.tr
                        : null,
                    child: step == 3
                        ? CareerPrimaryButton(
                      label: 'career_builder_generate_button'.tr,
                      icon: Icons.auto_awesome,
                      onTap: _generate,
                    )
                        : CareerPrimaryButton(
                      label: 'career_builder_continue'.tr,
                      onTap: _c.next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ------------------------------------------------------------ step 1

  Widget _stepDetails() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Title('career_builder_details_title'.tr),
      const SizedBox(height: 6),
      _Subtitle('career_builder_details_subtitle'.tr),
      const SizedBox(height: 18),
      _Field(
        'career_builder_full_name'.tr,
        _c.name,
        next: _roleFocus,
      ),
      _Field(
        'career_builder_current_role'.tr,
        _c.role,
        focusNode: _roleFocus,
        next: _companyFocus,
      ),
      _Field(
        'career_builder_company'.tr,
        _c.company,
        focusNode: _companyFocus,
        next: _locationFocus,
      ),
      _Field(
        'career_builder_location'.tr,
        _c.location,
        focusNode: _locationFocus,
        hint: 'career_builder_location_hint'.tr,
        last: true,
      ),
      _Label('career_builder_experience_label'.tr),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final b in ProfileBuilderFlowController.experienceBands)
            _ChoicePill(
              label: _bandKeys[b]!.tr,
              selected: _c.experience.value == b,
              onTap: () => _c.experience.value = b,
            ),
        ],
      ),
    ],
  );

  // ------------------------------------------------------------ step 2

  Widget _stepAudience() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Title('career_builder_who_title'.tr),
      const SizedBox(height: 6),
      _Subtitle('career_builder_who_subtitle'.tr),
      const SizedBox(height: 18),
      _Label('career_builder_goal_label'.tr),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final g in ProfileBuilderFlowController.goals)
            _ChoicePill(
              label: _goalKeys[g]!.tr,
              selected: _c.goal.value == g,
              onTap: () => _c.goal.value = g,
            ),
        ],
      ),
      const SizedBox(height: 20),
      _Label(
        'career_builder_audience_label'.tr,
        hint: 'career_builder_audience_hint_upto'.trParams({
          'max': ProfileBuilderFlowController.maxAudience,
        }),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final a in ProfileBuilderFlowController.audiences)
            _ChoicePill(
              label: _audienceKeys[a]!.tr,
              selected: _c.audience.contains(a),
              onTap: () => _c.toggleAudience(a),
            ),
        ],
      ),
    ],
  );

  // ------------------------------------------------------------ step 3

  Widget _stepTone() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Title('career_builder_tone_title'.tr),
      const SizedBox(height: 6),
      _Subtitle('career_builder_tone_subtitle'.tr),
      const SizedBox(height: 18),
      _Label('career_builder_tone_label'.tr),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in ProfileBuilderFlowController.tones)
            _ChoicePill(
              label: _toneKeys[t]!.tr,
              selected: _c.tone.value == t,
              onTap: () => _c.tone.value = t,
            ),
        ],
      ),
      const SizedBox(height: 20),
      _Label(
        'career_builder_wins_label'.tr,
        hint: 'career_builder_optional'.tr,
        hintStart: true,
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _c.wins,
        minLines: 4,
        maxLines: 6,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        style: _fieldText,
        decoration: _decoration(hint: 'career_builder_wins_hint'.tr),
      ),
    ],
  );
}

const _fieldText = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 14,
  color: AppColors.titleDark,
);

InputDecoration _decoration({String? hint}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 14,
      color: AppColors.textGrey,
    ),
    filled: true,
    fillColor: AppColors.scaffoldBg,
    contentPadding: const EdgeInsetsDirectional.symmetric(
      horizontal: 14,
      vertical: 14,
    ),
    border: border(AppColors.pillBorder),
    enabledBorder: border(AppColors.pillBorder),
    focusedBorder: border(AppColors.onboardingBtnEnd),
  );
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i < step
                    ? AppColors.onboardingBtnEnd
                    : AppColors.profileStepInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: AppColors.titleDark,
    ),
  );
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 13.5,
      height: 1.4,
      color: AppColors.textSubtitle,
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.label, {this.hint, this.hintStart = false});
  final String label;
  final String? hint;

  /// Hint sits right after the label ("(optional)") instead of at the end.
  final bool hintStart;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: AppColors.titleDark,
    );
    const hintStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 12,
      color: AppColors.textGrey,
    );
    if (hint != null && hintStart) {
      return Text.rich(
        TextSpan(
          style: labelStyle,
          children: [
            TextSpan(text: label),
            TextSpan(text: ' $hint', style: hintStyle),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: labelStyle)),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(hint!, textAlign: TextAlign.end, style: hintStyle),
          ),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(
      this.label,
      this.controller, {
        this.hint,
        this.last = false,
        this.focusNode,
        this.next,
      });
  final String label;
  final TextEditingController controller;
  final String? hint;

  /// The last field closes the keyboard instead of moving on.
  final bool last;

  /// This field's own focus node (needed when another field points to it).
  final FocusNode? focusNode;

  /// The field that gets focus when the user taps Next.
  final FocusNode? next;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            focusNode: focusNode,
            // Capitalise each word (names, roles, places).
            textCapitalization: TextCapitalization.words,
            textInputAction:
            last ? TextInputAction.done : TextInputAction.next,
            onSubmitted: (_) {
              if (last) {
                FocusScope.of(context).unfocus();
              } else {
                next?.requestFocus();
              }
            },
            style: _fieldText,
            decoration: _decoration(hint: hint),
          ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.onboardingBtnEnd : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.onboardingBtnEnd : AppColors.pillBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.titleDark,
          ),
        ),
      ),
    );
  }
}

/// Bottom bar: optional small note above the primary button, with a divider.
class _Footer extends StatelessWidget {
  const _Footer({required this.child, this.note});
  final Widget child;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.pillBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note != null) ...[
            Text(
              note!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11.5,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}