import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/career_widgets.dart';

enum _Source { pdf, link, text }

/// Profile Optimizer: choose how to share the LinkedIn profile. UI only;
/// "Analyze my profile" has no backend yet.
class ProfileOptimizerView extends StatefulWidget {
  const ProfileOptimizerView({super.key});

  @override
  State<ProfileOptimizerView> createState() => _ProfileOptimizerViewState();
}

class _ProfileOptimizerViewState extends State<ProfileOptimizerView> {
  _Source _source = _Source.pdf;
  final _link = TextEditingController();
  final _sections = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    _sections.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              const CareerAppBar(title: 'Profile Optimizer'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Let\'s check your profile',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.titleDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose how to share it. We only read it to score it.',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: AppColors.textSubtitle,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SourceCard(
                        selected: _source == _Source.pdf,
                        onTap: () => setState(() => _source = _Source.pdf),
                        title: 'Upload profile PDF',
                        badge: 'Most accurate',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'On your LinkedIn profile, tap More → Save to '
                              'PDF, then pick the file here.',
                              style: _bodyStyle,
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: careerComingSoon,
                              child: DashedBox(
                                color: AppColors.onboardingBtnEnd,
                                radius: 12,
                                child: Container(
                                  width: double.infinity,
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.file_upload_outlined,
                                        size: 20,
                                        color: AppColors.onboardingBtnEnd,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Choose PDF file',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onboardingBtnEnd,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SourceCard(
                        selected: _source == _Source.link,
                        onTap: () => setState(() => _source = _Source.link),
                        title: 'Paste profile link',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Field(
                              controller: _link,
                              hint: 'linkedin.com/in/your-name',
                              keyboardType: TextInputType.url,
                              onFocus: () =>
                                  setState(() => _source = _Source.link),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Works for public profiles only.',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 12.5,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SourceCard(
                        selected: _source == _Source.text,
                        onTap: () => setState(() => _source = _Source.text),
                        title: 'Paste sections by hand',
                        child: _source == _Source.text
                            ? _Field(
                                controller: _sections,
                                hint:
                                    'Paste your headline, about and '
                                    'experience here',
                                maxLines: 5,
                              )
                            : null,
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
                      '1 free scan left this month',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CareerPrimaryButton(
                      label: 'Analyze my profile',
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

const _bodyStyle = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 13.5,
  height: 1.35,
  color: AppColors.textSubtitle,
);

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.selected,
    required this.onTap,
    required this.title,
    this.badge,
    this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? badge;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.profileOptionSelectedBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.onboardingBtnEnd : AppColors.pillBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Radio(selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onboardingBtnEnd,
                      ),
                    ),
                  ),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 10),
              Padding(padding: const EdgeInsets.only(left: 34), child: child),
            ],
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.onboardingBtnEnd : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.onboardingBtnEnd : AppColors.dotInactive,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.circle, size: 8, color: Colors.white)
          : null,
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onFocus,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final VoidCallback? onFocus;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onTap: onFocus,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 15,
        color: AppColors.titleDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 15,
          color: AppColors.textGrey,
        ),
        filled: true,
        fillColor: AppColors.scaffoldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.onboardingBtnEnd),
        ),
      ),
    );
  }
}
