import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/ai_card_controller.dart';

class AiCardPreviewView extends StatelessWidget {
  const AiCardPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AiCardController>();
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          controller.resetPrompt();
          Get.until((route) => route.isFirst); // Home
        },
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Obx(
                  () => IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: controller.isSharing.value
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.titleDark,
                  ),
                )
                    : const Icon(Icons.ios_share,
                    size: 18, color: AppColors.titleDark),
                onPressed: (controller.isSharing.value ||
                    controller.generatedCard.value == null)
                    ? null
                    : () => controller.shareCard(),
              ),
            ),
          ),
        ),
        title: const Text(
          'Preview',
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
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isGenerating.value) {
            return const _GeneratingState();
          }

          final card = controller.generatedCard.value;

          // Generation failed and there is nothing to show: show the error
          // with a retry button instead of a blank screen.
          if (card == null) {
            return _ErrorState(
              message: controller.errorMessage.value,
              onRetry: controller.regenerate,
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: AspectRatio(
                          aspectRatio: 16 / 9.5,
                          child: _CardImage(path: card.frontImagePath),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: AspectRatio(
                          aspectRatio: 16 / 9.5,
                          child: _CardImage(path: card.backImagePath),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Obx(
                            () => ElevatedButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.saveCardToGallery(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: controller.isSaving.value
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Download'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: controller.regenerate,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Regenerate'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String path;

  const _CardImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final isAsset = path.startsWith('assets/');

    Widget errorBox(BuildContext _, Object __, StackTrace? ___) {
      return Container(
        color: const Color(0xFFE4E2F2),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: AppColors.pillLabelGrey),
      );
    }

    if (isAsset) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: errorBox,
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: errorBox,
    );
  }
}

class _GeneratingState extends StatelessWidget {
  const _GeneratingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 20),
          Text(
            'AI Generating Your Card...',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.titleDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'This will take a few seconds',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Couldn't generate your card",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.titleDark,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Try again'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}