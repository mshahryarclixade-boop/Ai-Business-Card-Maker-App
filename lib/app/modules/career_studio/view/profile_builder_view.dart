import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile_setup/service/profile_store.dart';
import '../widgets/career_widgets.dart';
import 'profile_generated_view.dart';
import 'package:get/get.dart' hide Trans;
import '../../../core/translations/tr_extension.dart';

/// Profile Builder: goal, audience, industry and work experience.
/// UI only; "Generate my profile" has no backend yet.
class ProfileBuilderView extends StatefulWidget {
  const ProfileBuilderView({super.key});

  @override
  State<ProfileBuilderView> createState() => _ProfileBuilderViewState();
}

class _ProfileBuilderViewState extends State<ProfileBuilderView> {
  static const _goals = [
    'Get hired',
    'Win clients',
    'Raise funding',
    'Build authority',
  ];

  static const _audiences = [
    'Startup founders',
    'Recruiters',
    'Product managers',
    'Agencies',
    'Investors',
    'Small businesses',
  ];

  // Display keys for the English ids above (the ids go into profileData;
  // goal keys live in career_widgets.dart).
  static const _audienceKeys = {
    'Startup founders': 'career_builder_audience_founders',
    'Recruiters': 'career_builder_audience_recruiters',
    'Product managers': 'career_builder_audience_pms',
    'Agencies': 'career_builder_audience_agencies',
    'Investors': 'career_builder_audience_investors',
    'Small businesses': 'career_builder_audience_small_biz',
  };

  static const _maxAudience = 3;

  String _goal = 'Win clients';

  final Set<String> _selectedAudience = {
    'Startup founders',
    'Product managers',
  };

  final _industry = TextEditingController();
  final _tenure = TextEditingController();

  // NEW: Multiple work experience entries.
  final List<_WorkExperienceEntry> _experiences = [];

  @override
  void initState() {
    super.initState();
    _addExperience();
  }

  @override
  void dispose() {
    _industry.dispose();
    _tenure.dispose();

    for (final experience in _experiences) {
      experience.dispose();
    }

    super.dispose();
  }

  void _toggleAudience(String a) {
    setState(() {
      if (_selectedAudience.contains(a)) {
        _selectedAudience.remove(a);
      } else if (_selectedAudience.length < _maxAudience) {
        _selectedAudience.add(a);
      }
    });
  }

  // NEW: Add a work experience entry.
  void _addExperience() {
    setState(() {
      _experiences.add(_WorkExperienceEntry());
    });
  }

  // NEW: Remove a work experience entry.
  void _removeExperience(int index) {
    setState(() {
      _experiences[index].dispose();
      _experiences.removeAt(index);
    });
  }

  // NEW: Pass entered data to the generated profile screen.
  void _generateProfile() {
    final experiences = _experiences
        .map((experience) {
          return {
            'role': experience.roleController.text.trim(),
            'company': experience.companyController.text.trim(),
            'tenure': experience.tenureController.text.trim(),
          };
        })
        .where((experience) {
          return experience.values.any((value) => value.toString().isNotEmpty);
        })
        .toList();

    Get.to(
      () => ProfileGeneratedView(
        profileData: {
          'goal': _goal,
          'targetAudience': _selectedAudience.toList(),
          'industry': _industry.text.trim(),
          'tenure': _tenure.text.trim(),
          'experiences': experiences,
        },
      ),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              CareerAppBar(title: 'career_builder_title'.tr),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const _StepBar(step: 2, total: 3),
                      // const SizedBox(height: 22),
                      Text(
                        'career_builder_who_title'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.titleDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'career_builder_who_subtitle'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.textSubtitle,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _CardSummary(),
                      const SizedBox(height: 18),

                      _SectionLabel('career_builder_goal_label'.tr),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 4,
                        runSpacing: 6,
                        children: [
                          for (final g in _goals)
                            _ChoicePill(
                              label: kCareerGoalKeys[g]!.tr,
                              selected: _goal == g,
                              onTap: () => setState(() => _goal = g),
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      _SectionLabel(
                        'career_builder_audience_label'.tr,
                        hint: 'career_builder_audience_hint'
                            .trParams({'max': _maxAudience}),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in _audiences)
                            _ChoicePill(
                              label: _audienceKeys[a]!.tr,
                              selected: _selectedAudience.contains(a),
                              onTap: () => _toggleAudience(a),
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      _SectionLabel('career_builder_industry_label'.tr),
                      const SizedBox(height: 10),

                      // Existing industry field, unchanged in style.
                      TextField(
                        controller: _industry,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          color: AppColors.titleDark,
                        ),
                        decoration: _fieldDecoration(
                          hint: 'career_builder_industry_hint'.tr,
                        ),
                      ),

                      // NEW: Total industry/company tenure.
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tenure,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          color: AppColors.titleDark,
                        ),
                        decoration: _fieldDecoration(
                          hint: 'career_builder_total_experience_hint'.tr,
                        ),
                      ),

                      // NEW: Multiple work experience section.
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _SectionLabel(
                              'career_builder_work_experience_label'.tr,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addExperience,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('career_builder_add'.tr),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.onboardingBtnEnd,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...List.generate(_experiences.length, (index) {
                        final experience = _experiences[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBg,
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
                                      'career_builder_experience_n'.trParams({'n': index + 1}),
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.titleDark,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'career_builder_remove_experience'.tr,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _removeExperience(index),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: experience.roleController,
                                textInputAction: TextInputAction.next,
                                style: _fieldTextStyle,
                                decoration: _fieldDecoration(
                                  hint: 'career_builder_role_hint'.tr,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: experience.companyController,
                                textInputAction: TextInputAction.next,
                                style: _fieldTextStyle,
                                decoration: _fieldDecoration(
                                  hint: 'career_builder_company_hint'.tr,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: experience.tenureController,
                                textInputAction: TextInputAction.done,
                                style: _fieldTextStyle,
                                decoration: _fieldDecoration(
                                  hint: 'career_builder_duration_hint'.tr,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Existing bottom button layout retained.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'career_builder_free_build_note'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CareerPrimaryButton(
                      label: 'career_builder_generate_button'.tr,
                      icon: Icons.auto_awesome,
                      onTap: _generateProfile,
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

  // NEW: Shared field decoration matching the existing Industry field.
  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textGrey,
      ),
      filled: true,
      fillColor: AppColors.scaffoldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.pillBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.pillBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.onboardingBtnEnd),
      ),
    );
  }

  static const TextStyle _fieldTextStyle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    fontSize: 16,
    color: AppColors.titleDark,
  );
}

// NEW: Controllers for each work experience entry.
class _WorkExperienceEntry {
  final roleController = TextEditingController();
  final companyController = TextEditingController();
  final tenureController = TextEditingController();

  void dispose() {
    roleController.dispose();
    companyController.dispose();
    tenureController.dispose();
  }
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
              height: 4,
              decoration: BoxDecoration(
                color: i < step
                    ? AppColors.profileStepActive
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

/// "From your card": the name, role and company already saved in the app.
class _CardSummary extends StatelessWidget {
  const _CardSummary();

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final p = ProfileStore.to.profile.value;
    final name = p.fullName.trim().isEmpty ? 'career_builder_your_name'.tr : p.fullName.trim();
    final role = [
      p.designation.trim(),
      p.companyName.trim(),
    ].where((e) => e.isNotEmpty).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.onboardingBtnEnd,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name).isEmpty ? '?' : _initials(name),
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
                if (role.isNotEmpty)
                  Text(
                    role,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSubtitle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'career_builder_from_card'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.onboardingBtnEnd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.titleDark,
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hint!,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textGrey,
              ),
            ),
          ),
        ],
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.titleDark,
          ),
        ),
      ),
    );
  }
}
