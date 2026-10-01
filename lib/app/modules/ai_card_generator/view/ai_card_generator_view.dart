import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../paywall/view/paywall_view.dart';
import '../../profile/widgets/dashed_border.dart';
import '../controller/ai_card_controller.dart';
import '../service/ai_card_service.dart';
import 'ai_card_preview_view.dart';

class AiCardGeneratorView extends StatelessWidget {
  final String? initialPrompt;

  final File? initialImage;

  const AiCardGeneratorView({
    super.key,
    this.initialPrompt,
    this.initialImage,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AiCardController());
    controller.applyInitialPrompt(initialPrompt);
    controller.applyInitialImage(initialImage);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.titleDark),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'AI Card Generator',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Get.to(
                        () => const PaywallView(),
                    transition: Transition.rightToLeft,
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.crown,
                    size: 18,
                    color: Color(0xFFF5A623),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            // 24px side padding = 345px wide content on the 393px design.
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReferenceImagePicker(controller: controller),
                const SizedBox(height: 24),

                const Text(
                  'No Design Yet? Try a Ready Template.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleDark,
                  ),
                ),
                const SizedBox(height: 8),
                _ReadyTemplateRow(controller: controller),
                const SizedBox(height: 16),

                const Text(
                  'Enter Prompt',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleDark,
                  ),
                ),
                const SizedBox(height: 8),
                _PromptField(controller: controller),
                const SizedBox(height: 20),

                Center(
                  child: SizedBox(
                    width: 195,
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 24,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Obx(
                                  () => Switch(
                                value: controller.autoFillProfile.value,
                                onChanged: controller.toggleAutoFill,
                                activeColor: AppColors.primary,
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 144,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Auto fill profile details',
                              maxLines: 1,
                              style: AppTextStyles.splashSubtitle.copyWith(
                                fontSize: 14,
                                color: AppColors.titleDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: Obx(() {
                    final isBusy = controller.isGenerating.value;
                    final hasImage = controller.referenceImage.value != null ||
                        controller.selectedTemplateId.value.isNotEmpty;

                    return ElevatedButton.icon(
                      onPressed: (isBusy || !hasImage)
                          ? null
                          : () async {
                        if (!controller.canGenerate) {
                          // Surfaces the validation snackbar.
                          controller.generate();
                          return;
                        }

                        // Shows the No Internet dialog and stops here
                        final online = await Get.find<ConnectivityService>()
                            .ensureInternet();
                        if (!online) return;

                        Get.to(() => const AiCardPreviewView());
                        controller.generate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isBusy
                            ? AppColors.primary.withOpacity(0.6)
                            : const Color(0xFFAEAEAE),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: isBusy
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        isBusy ? 'Generating…' : 'Generate Card',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceImagePicker extends StatelessWidget {
  final AiCardController controller;

  const _ReferenceImagePicker({required this.controller});

  /// Asks the user whether to use the camera or the gallery, then
  /// hands the chosen source to the controller.
  void _showSourceSheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleDark,
                  ),
                ),
                onTap: () {
                  Get.back();
                  controller.pickReferenceImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleDark,
                  ),
                ),
                onTap: () {
                  Get.back();
                  controller.pickReferenceImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final image = controller.referenceImage.value;

      return DashedBorder(
        radius: 14,
        color: AppColors.primary.withOpacity(0.5),
        child: GestureDetector(
          onTap: _showSourceSheet,
          child: Container(
            width: double.infinity,
            height: 220, // design: 345 x 220
            padding: image == null
                ? const EdgeInsets.symmetric(vertical: 28, horizontal: 16)
                : EdgeInsets.zero,
            alignment: Alignment.center,
            child: image == null
                ? Column(
              children: [
                Image.asset(
                  'assets/icons/add_image.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload reference image',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI will use this as inspiration',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Supported formats JPEG, JPG, PNG, HEIC and TIFF',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  'Max file size 50 MB',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            )

            /// UPLOAD IMAGE BOX FIT
                : Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    image,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: GestureDetector(
                    onTap: controller.clearReferenceImage,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ReadyTemplateRow extends StatelessWidget {
  final AiCardController controller;

  const _ReadyTemplateRow({required this.controller});

  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    // Single source of truth: pulled straight from
    // AiCardService's kReadyTemplateAssets, so adding a new
    // template there makes it show up here automatically —
    // no second list to keep in sync.
    final entries = kReadyTemplateAssets.entries.toList();

    return SizedBox(
      height: 120, // design: 345 x 120
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Two templates fit the row exactly, with a 16px gap between them.
          final itemWidth = (constraints.maxWidth - _gap) / 2;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: _gap),
            itemBuilder: (_, i) {
              final id = entries[i].key;
              final imagePath = entries[i].value;

              return GestureDetector(
                onTap: () => controller.selectReadyTemplate(id),
                child: Obx(
                      () => Container(
                    width: itemWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      border: Border.all(
                        color: controller.selectedTemplateId.value == id
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),

                    /// TEMPLATES BOX FIT
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE4E2F2),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image,
                            color: AppColors.pillLabelGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PromptField extends StatelessWidget {
  final AiCardController controller;

  const _PromptField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 135, // design: 345 x 135
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFCDCDCD),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller.promptController,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        maxLength: AiCardController.promptMaxLength,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Describe your ideal design...',
          hintStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          counterStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}