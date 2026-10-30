import '../../../core/widgets/tap_target.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/career_widgets.dart';
import '../../../core/translations/tr_extension.dart';

/// Generated profile result. UI only, dummy data.
class ProfileGeneratedView extends StatefulWidget {
  const ProfileGeneratedView({super.key, required this.profileData});

  final Map<String, dynamic> profileData;

  static const _skills = [
    'career_generated_skill_product_design',
    'career_generated_skill_saas_ux',
    'career_generated_skill_design_systems',
    'career_generated_skill_user_research',
    'career_generated_skill_figma',
  ];

  @override
  State<ProfileGeneratedView> createState() => _ProfileGeneratedViewState();
}

class _ProfileGeneratedViewState extends State<ProfileGeneratedView> {
  final ImagePicker _imagePicker = ImagePicker();

  File? _profileImage;

  Future<void> _showImageOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'career_generated_change_photo'.tr,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('career_generated_choose_gallery'.tr),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('career_generated_take_photo'.tr),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'career_generated_remove_photo'.tr,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _profileImage = null);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _profileImage = File(pickedFile.path);
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('career_generated_image_error'.tr),
        ),
      );
    }
  }

  String _profileValue(String key, {String fallback = ''}) {
    final value = widget.profileData[key];

    if (value == null) return fallback;

    if (value is List) {
      return value.join(', ');
    }

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  List<Map<String, dynamic>> get _experiences {
    final value = widget.profileData['experiences'];

    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: CareerAppBar(
                title: 'career_generated_title'.tr,
                trailing: TapTarget(child: GestureDetector(
                  onTap: careerComingSoon,
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color: AppColors.onboardingBtnEnd,
                  ),
                )),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _Header(
                      profileImage: _profileImage,
                      onAvatarTap: _showImageOptions,
                      name: _profileValue('fullName', fallback: 'career_generated_sample_name'.tr),
                      headline: _buildHeadline(),
                      location: _profileValue(
                        'location',
                        fallback: 'career_generated_sample_location'.tr,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        children: [
                          _AboutCard(
                            industry: _profileValue(
                              'industry',
                              fallback: 'career_generated_sample_industry'.tr,
                            ),
                            goal: _goalLabel(
                              _profileValue('goal', fallback: 'Win clients'),
                            ),
                          ),
                          const SizedBox(height: 9),
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'career_generated_top_skills'.tr,
                                        style: _titleStyle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'career_generated_ranked'.tr,
                                        textAlign: TextAlign.end,
                                        style: _smallGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final skill
                                        in ProfileGeneratedView._skills)
                                      _SkillChip(skill),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 9),

                          // Work experience supplied by ProfileBuilderView.
                          _Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CareerIconTile(Icons.work_outline_rounded),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'career_generated_experience_featured'.tr,
                                        style: _titleStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _InfoLine(
                                  title: 'career_generated_industry_company'.tr,
                                  value: _profileValue(
                                    'industry',
                                    fallback: 'career_generated_not_provided'.tr,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _InfoLine(
                                  title: 'career_generated_total_experience'.tr,
                                  value: _profileValue(
                                    'tenure',
                                    fallback: 'career_generated_not_provided'.tr,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'career_generated_work_experience'.tr,
                                  style: _titleStyle,
                                ),
                                const SizedBox(height: 8),
                                if (_experiences.isEmpty)
                                  Text(
                                    'career_generated_no_experience'.tr,
                                    style: _smallGrey,
                                  )
                                else
                                  ..._experiences.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final experience = entry.value;

                                    final role =
                                        experience['role']?.toString().trim() ??
                                        '';
                                    final company =
                                        experience['company']
                                            ?.toString()
                                            .trim() ??
                                        '';
                                    final duration =
                                        experience['tenure']
                                            ?.toString()
                                            .trim() ??
                                        '';

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.work_history_outlined,
                                            size: 20,
                                            color: AppColors.onboardingBtnEnd,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  role.isEmpty
                                                      ? 'career_generated_experience_n'
                                                          .trParams({'n': index + 1})
                                                      : role,
                                                  style: const TextStyle(
                                                    fontFamily: AppTextStyles
                                                        .fontFamily,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.titleDark,
                                                  ),
                                                ),
                                                if (company.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 3,
                                                        ),
                                                    child: Text(
                                                      company,
                                                      style: _bodyStyle,
                                                    ),
                                                  ),
                                                if (duration.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 3,
                                                        ),
                                                    child: Text(
                                                      duration,
                                                      style: _smallGrey,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CareerPrimaryButton(
                    label: 'career_generated_copy_all_button'.tr,
                    icon: Icons.copy_rounded,
                    onTap: careerComingSoon,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'career_generated_paste_hint'.tr,
                    textAlign: TextAlign.center,
                    style: _smallGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Goals are stored as English ids; show them in the current language.
  String _goalLabel(String goal) {
    final key = kCareerGoalKeys[goal];
    return key == null ? goal : key.tr;
  }

  String _buildHeadline() {
    final industry = _profileValue('industry');
    final goal = _profileValue('goal');

    if (industry.isEmpty && goal.isEmpty) {
      return 'career_generated_sample_headline'.tr;
    }

    final parts = <String>[];

    if (industry.isNotEmpty) parts.add(industry);
    if (goal.isNotEmpty) {
      parts.add(
        'career_generated_headline_focus'.trParams({'goal': _goalLabel(goal)}),
      );
    }

    return parts.join(' | ');
  }
}

const _titleStyle = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w800,
  color: AppColors.titleDark,
);

const _smallGrey = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 11,
  color: AppColors.textGrey,
);

const _bodyStyle = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 12.5,
  height: 1.3,
  color: AppColors.textSubtitle,
);

class _Header extends StatelessWidget {
  const _Header({
    required this.profileImage,
    required this.onAvatarTap,
    required this.name,
    required this.headline,
    required this.location,
  });

  final File? profileImage;
  final VoidCallback onAvatarTap;
  final String name;
  final String headline;
  final String location;

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 110,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 84,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.onboardingBtnEnd,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      PositionedDirectional(
                        end: -30,
                        top: -40,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Text(
                          'career_generated_banner'.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 10,
                  top: 50,
                  child: GestureDetector(
                    onTap: onAvatarTap,
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: profileImage != null
                                  ? Image.file(profileImage!, fit: BoxFit.cover)
                                  : Center(
                                      child: Text(
                                        _initials(name).isEmpty
                                            ? 'career_generated_sample_initials'.tr
                                            : _initials(name),
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.onboardingBtnEnd,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.onboardingBtnEnd,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.titleDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            headline,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w400,
              color: AppColors.titleDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location,
            style: _smallGrey.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
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
          child: child,
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.industry, required this.goal});

  final String industry;
  final String goal;

  @override
  Widget build(BuildContext context) {
    final aboutText = industry.isEmpty
        ? 'career_generated_about_sample'.tr
        : 'career_generated_about_text'
              .trParams({'industry': industry, 'goal': goal});

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('career_generated_about'.tr, style: _titleStyle),
              GestureDetector(
                onTap: careerComingSoon,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppColors.onboardingBtnEnd,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'career_generated_copy'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onboardingBtnEnd,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            aboutText,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: AppColors.textSubtitle,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: careerComingSoon,
            child: Text(
              'career_generated_read_full'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _smallGrey),
        const SizedBox(height: 3),
        Text(value.isEmpty ? 'career_generated_not_provided'.tr : value, style: _bodyStyle),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.tr,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.titleDark,
        ),
      ),
    );
  }
}
