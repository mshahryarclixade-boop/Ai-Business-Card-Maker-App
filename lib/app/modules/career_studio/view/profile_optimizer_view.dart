import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/profile_optimizer_controller.dart';
import '../widgets/career_widgets.dart';
import '../widgets/pdf_help_sheet.dart';
import '../../../core/translations/tr_extension.dart';

class ProfileOptimizerView extends GetView<ProfileOptimizerController> {
  const ProfileOptimizerView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProfileOptimizerController());

    return Scaffold(
      backgroundColor: AppColors.splashBg,
      // The Analyze button stays at the bottom when the keyboard opens.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              CareerAppBar(title: 'career_optimizer_title'.tr),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    16 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'career_optimizer_heading'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.titleDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'career_optimizer_subtitle'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.textSubtitle,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PdfCard(controller: controller),
                      const SizedBox(height: 12),
                      _ImagesCard(controller: controller),
                      const SizedBox(height: 12),
                      _TextCard(controller: controller),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'career_optimizer_free_scan_note'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CareerPrimaryButton(
                      label: 'career_optimizer_analyze_button'.tr,
                      onTap: controller.analyze,
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

// ---------------------------------------------------------------------------
// Option cards
// ---------------------------------------------------------------------------

class _PdfCard extends StatelessWidget {
  const _PdfCard({required this.controller});

  final ProfileOptimizerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pdf = controller.pdf.value;

      return _SourceCard(
        selected: controller.source.value == ProfileSource.pdf,
        onTap: () => controller.selectSource(ProfileSource.pdf),
        title: 'career_optimizer_pdf_title'.tr,
        badge: 'career_optimizer_pdf_badge'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'career_optimizer_pdf_instructions'.tr,
              style: _bodyStyle,
            ),
            const SizedBox(height: 12),
            _DashedButton(
              icon: pdf == null
                  ? Icons.file_upload_outlined
                  : Icons.picture_as_pdf_outlined,
              label: pdf?.name ?? 'career_optimizer_pdf_choose'.tr,
              // Explains how to export the PDF first, then opens the picker.
              onTap: () => showPdfHelpSheet(
                context,
                onChooseFile: controller.pickPdf,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ImagesCard extends StatelessWidget {
  const _ImagesCard({required this.controller});

  final ProfileOptimizerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final images = controller.images;
      final max = ProfileOptimizerController.maxImages;

      return _SourceCard(
        selected: controller.source.value == ProfileSource.images,
        onTap: () => controller.selectSource(ProfileSource.images),
        title: 'career_optimizer_images_title'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < images.length; i++)
                    _Thumb(
                      file: File(images[i].path),
                      onRemove: () => controller.removeImage(i),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (images.length < max)
              _DashedButton(
                icon: Icons.add_photo_alternate_outlined,
                label: images.isEmpty
                    ? 'career_optimizer_images_select'.tr
                    : 'career_optimizer_images_add_more'.tr,
                onTap: controller.pickImages,
              ),
            const SizedBox(height: 8),
            Text(
              'career_optimizer_images_count'
                  .trParams({'count': images.length, 'max': max}),
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.controller});

  final ProfileOptimizerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.source.value == ProfileSource.text;

      return _SourceCard(
        selected: selected,
        onTap: () => controller.selectSource(ProfileSource.text),
        title: 'career_optimizer_text_title'.tr,
        child: selected
            ? _Field(
          controller: controller.sections,
          hint: 'career_optimizer_text_hint'.tr,
          maxLines: 5,
        )
            : null,
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

const _bodyStyle = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 13.5,
  height: 1.35,
  color: AppColors.textSubtitle,
);

class _DashedButton extends StatelessWidget {
  const _DashedButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DashedBox(
        color: AppColors.onboardingBtnEnd,
        radius: 12,
        child: Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.onboardingBtnEnd),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onboardingBtnEnd,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(file, fit: BoxFit.cover, cacheWidth: 200),
            ),
          ),
          PositionedDirectional(
            top: -6,
            end: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.titleDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              Padding(padding: const EdgeInsetsDirectional.only(start: 34), child: child),
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
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    // Always outlined, so the field stays visible whether empty, focused or
    // filled.
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFC9C9DB), width: 1.2),
    );
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
          borderSide: const BorderSide(
            color: AppColors.onboardingBtnEnd,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}