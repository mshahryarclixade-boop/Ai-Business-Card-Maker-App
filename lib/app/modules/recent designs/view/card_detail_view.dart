import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../ai_card_generator/view/ai_card_generator_view.dart';
import '../../custom_create/view/card_editor_view.dart';

/// Preview screen opened when a card is tapped from either My Cards
/// or Ai Cards. Shows front + back, with Download / Edit at the bottom.
class CardDetailView extends StatelessWidget {
  final RecentDesign design;
  final VoidCallback? onDownload;
  final VoidCallback? onEdit;

  const CardDetailView({
    super.key,
    required this.design,
    this.onDownload,
    this.onEdit,
  });

  Future<void> _downloadCard() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          Get.snackbar(
            'Permission needed',
            'Allow photo/gallery access to save your card.',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(15),
          );
          return;
        }
      }

      await Gal.putImage(design.path, album: 'AI Business Card');
      if (design.backPath != null) {
        await Gal.putImage(design.backPath!, album: 'AI Business Card');
      }

      Get.snackbar(
        'Saved',
        'Card saved to your gallery.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } catch (e) {
      Get.snackbar(
        'Could not save',
        'Something went wrong while saving to gallery.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  void _editCard() {
    debugPrint('EDIT TAPPED: id=${design.id}, isAi=${design.isAiGenerated}, '
        'hasData=${design.designData != null}');

    // AI generated cards re-open in the AI Card Generator with the card's
    // image already placed in the reference image section, so it can be
    // edited with AI again. Normal cards keep using the manual editor.
    if (design.isAiGenerated) {
      Get.to(() => AiCardGeneratorView(initialImage: design.file));
      return;
    }

    Get.to(() => CardEditorView(design: design));
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DETAIL BUILD: onEdit passed? ${onEdit != null}');
    final downloadAction = onDownload ?? _downloadCard;
    final editAction = onEdit ?? _editCard;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
                    child: Column(
                      children: [
                        _DesignPreviewCard(file: design.file),
                        const SizedBox(height: 16),
                        _DesignPreviewCard(
                          file: design.backFile ?? design.file,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: downloadAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Download',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: editAction,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 20,
              child: _CircleBackButton(onTap: () => Get.back()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignPreviewCard extends StatelessWidget {
  final File file;
  const _DesignPreviewCard({required this.file});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.arrow_back,
            color: Colors.black, size: 20),
      ),
    );
  }
}