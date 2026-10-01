import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/profile_controller.dart';
import '../widgets/dashed_border.dart';
import '../widgets/social_link_picker.dart';

class CreateProfileView extends StatefulWidget {
  const CreateProfileView({super.key});

  @override
  State<CreateProfileView> createState() => _CreateProfileViewState();
}

class _CreateProfileViewState extends State<CreateProfileView> {
  static const double _sectionGap = 18;
  static const double _fieldGap = 10;

  late final ProfileController controller;

  // Icon asset picked for each entry in controller.socialLinkControllers,
  // kept in the same order/length. Populated when a link is added through
  // _openAddLinkSheet(); kept in sync on removal.
  final List<String> _socialLinkIcons = [];

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    final args = Get.arguments;
    final isBlank = args is Map && args['blank'] == true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isBlank) {
        controller.startBlankProfile();
      } else {
        controller.loadProfile();
      }
    });
  }

  Future<void> _openAddLinkSheet() async {
    final result = await pickSocialLink(context);
    if (result == null) return;

    controller.addSocialLinkField();
    controller.socialLinkControllers.last.text = result.url;

    setState(() => _socialLinkIcons.add(result.iconAsset));
  }

  void _removeSocialLinkField(int i) {
    setState(() {
      if (i < _socialLinkIcons.length) {
        _socialLinkIcons.removeAt(i);
      }
      controller.removeSocialLinkField(i);
    });
  }

  void _save(BuildContext context) {
    if (controller.isSaving.value || controller.showSuccess.value) return;

    final firstName = controller.firstNameController.text.trim();
    final lastName = controller.lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      Get.snackbar(
        'Incomplete Profile',
        'Please enter your first and last name.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    controller.saveProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Obx(
              () => Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileImages(),
                    const SizedBox(height: 22),
                    ..._buildPersonalDetailsSection(),
                    const SizedBox(height: _sectionGap),
                    ..._buildProfessionalDetailsSection(),
                    const SizedBox(height: _sectionGap),
                    ..._buildContactDetailsSection(),
                    const SizedBox(height: _sectionGap),
                    ..._buildSocialLinksSection(),
                  ],
                ),
              ),
              if (controller.showSuccess.value)
                const _CreateProfileSavedOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.scaffoldBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Colors.black,
        ),
        onPressed: () {
          FocusScope.of(context).unfocus();
          controller.loadProfile();
          Get.back();
        },
      ),
      title: const Text(
        'Create Profile',
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------

  Widget _buildProfileImages() {
    return Obx(
          () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ProfileImagePicker(
            icon: Icons.person,
            isProfile: true,
            image: controller.frontImage.value,
            onTap: controller.pickFrontImage,
          ),
          const SizedBox(width: 24),
          _ProfileImagePicker(
            icon: Icons.business_outlined,
            isProfile: false,
            image: controller.coverImage.value,
            onTap: controller.pickCoverImage,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPersonalDetailsSection() {
    return [
      const _SectionTitle(
        icon: Icons.person_outline_rounded,
        title: 'Personal Details',
      ),
      const SizedBox(height: _fieldGap),
      Row(
        children: [
          Expanded(
            child: _ProfileField(
              controller: controller.firstNameController,
              hint: 'First Name',
            ),
          ),
          const SizedBox(width: _fieldGap),
          Expanded(
            child: _ProfileField(
              controller: controller.lastNameController,
              hint: 'Last Name',
            ),
          ),
        ],
      ),
      const SizedBox(height: _fieldGap),
      _ProfileField(
        controller: controller.taglineController,
        hint: 'Tagline e.g. Helping brands grow digitally',
      ),
    ];
  }

  List<Widget> _buildProfessionalDetailsSection() {
    return [
      const _SectionTitle(
        icon: Icons.business_center_outlined,
        title: 'Professional Details',
      ),
      const SizedBox(height: _fieldGap),
      _ProfileField(
        controller: controller.companyNameController,
        hint: 'Company Name',
        prefixIcon: Icons.business_outlined,
      ),
      const SizedBox(height: _fieldGap),
      _ProfileField(
        controller: controller.jobTitleController,
        hint: 'Job Title',
        prefixIcon: Icons.badge_outlined,
      ),
      const SizedBox(height: _fieldGap),
      _ProfileField(
        controller: controller.companyWebsiteController,
        hint: 'Company Website',
        prefixIcon: Icons.language_rounded,
      ),
    ];
  }

  List<Widget> _buildContactDetailsSection() {
    return [
      const _SectionTitle(
        icon: Icons.phone_outlined,
        title: 'Contact Details',
      ),
      const SizedBox(height: _fieldGap),
      _ProfileField(
        controller: controller.emailController,
        hint: 'loremipsum@gmail.com',
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: _fieldGap),
      _ProfileField(
        controller: controller.phoneController,
        hint: '+92308-5687901',
        prefixIcon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: _fieldGap),
      _ProfileField(
        controller: controller.locationController,
        hint: 'loremipsum, Faisalabad',
        prefixIcon: Icons.location_on_outlined,
      ),
    ];
  }

  List<Widget> _buildSocialLinksSection() {
    return [
      const _SectionTitle(icon: Icons.link_rounded, title: 'Social Links'),
      const SizedBox(height: _fieldGap),
      Obx(
            () => Column(
          children: List.generate(
            controller.socialLinkControllers.length,
            _buildSocialLinkRow,
          ),
        ),
      ),
      _buildAddLinkButton(),
    ];
  }

  Widget _buildSocialLinkRow(int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _fieldGap),
      child: Row(
        children: [
          Expanded(
            child: _ProfileField(
              controller: controller.socialLinkControllers[i],
              hint: 'e.g. linkedin.com/in/yourname',
              prefixIcon: Icons.link_rounded,
              prefixImagePath:
              i < _socialLinkIcons.length ? _socialLinkIcons[i] : null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeSocialLinkField(i),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddLinkButton() {
    return GestureDetector(
      onTap: _openAddLinkSheet,
      child: DashedBorder(
        radius: 10,
        color: AppColors.primary.withOpacity(0.5),
        child: Container(
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.add_rounded,
                size: 18,
                color: Color(0xFFF5A623),
              ),
              const SizedBox(width: 8),
              Text(
                'Add custom links',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Small presentational widgets
// ---------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E24),
          ),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  // When set, shown instead of prefixIcon — used for social-link rows
  // added through the platform picker, so each row shows its platform's
  // logo instead of the generic link icon.
  final String? prefixImagePath;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;

  const _ProfileField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.prefixImagePath,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    Widget? prefix;
    if (prefixImagePath != null) {
      prefix = Padding(
        padding: const EdgeInsets.all(9),
        child: Image.asset(prefixImagePath!, fit: BoxFit.contain),
      );
    } else if (prefixIcon != null) {
      prefix = Icon(prefixIcon, size: 16, color: AppColors.primary);
    }

    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          color: Color(0xFF222228),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            color: Color(0xFFB5B5BD),
          ),
          prefixIcon: prefix,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _ProfileImagePicker extends StatelessWidget {
  final IconData icon;
  final bool isProfile;
  final File? image;
  final VoidCallback? onTap;

  const _ProfileImagePicker({
    required this.icon,
    required this.isProfile,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DashedBorder(
            radius: isProfile ? 40 : 12,
            color: AppColors.primary.withOpacity(0.6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isProfile ? 40 : 12),
              child: Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                ),
                child: hasImage
                    ? Image.file(image!, width: 78, height: 78, fit: BoxFit.cover)
                    : (isProfile ? _personPlaceholder() : _logoPlaceholder()),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personPlaceholder() {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 22, color: Colors.white),
    );
  }

  Widget _logoPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          'Company\nLogo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 9,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _CreateProfileSavedOverlay extends StatelessWidget {
  const _CreateProfileSavedOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.12),
            child: Center(
              child: Container(
                width: 155,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Profile Saved',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Auto-fill is now active.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10,
                        height: 1.4,
                        color: AppColors.textSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}