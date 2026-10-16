import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile_setup/service/profile_store.dart';
import '../widgets/career_widgets.dart';

/// Profile Builder: goal, audience and industry. UI only; "Generate my
/// profile" has no backend yet.
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
  static const _maxAudience = 3;

  String _goal = 'Win clients';
  final Set<String> _selectedAudience = {
    'Startup founders',
    'Product managers',
  };
  final _industry = TextEditingController();

  @override
  void dispose() {
    _industry.dispose();
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
              const CareerAppBar(title: 'Profile Builder'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const _StepBar(step: 2, total: 3),
                      // const SizedBox(height: 22),
                      const Text(
                        'Who should find you?',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.titleDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'We tune your headline and keywords so these people '
                        'see you in search.',
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
                      const _SectionLabel('Your main goal'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 4,
                        runSpacing: 6,
                        children: [
                          for (final g in _goals)
                            _ChoicePill(
                              label: g,
                              selected: _goal == g,
                              onTap: () => setState(() => _goal = g),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel(
                        'Who do you want to reach?',
                        hint: 'Pick up to $_maxAudience',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in _audiences)
                            _ChoicePill(
                              label: a,
                              selected: _selectedAudience.contains(a),
                              onTap: () => _toggleAudience(a),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Industry'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _industry,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          color: AppColors.titleDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Design & SaaS',
                          hintStyle: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            color: AppColors.textGrey,
                          ),
                          filled: true,
                          fillColor: AppColors.scaffoldBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.pillBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.pillBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.onboardingBtnEnd,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Uses your 1 free build this month',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CareerPrimaryButton(
                      label: 'Generate my profile',
                      icon: Icons.auto_awesome,
                      onTap: careerComingSoon,
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
    final name = p.fullName.trim().isEmpty ? 'Your name' : p.fullName.trim();
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
            child: const Text(
              'From your card',
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
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.titleDark,
          ),
        ),
        if (hint != null)
          Text(
            hint!,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textGrey,
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
