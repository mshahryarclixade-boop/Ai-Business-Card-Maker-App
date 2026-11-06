import '../../../core/widgets/tap_target.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../../ai_card_generator/view/ai_card_generator_view.dart';
import '../../custom_create/view/card_editor_view.dart';
import '../../../core/translations/tr_extension.dart';

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

  Future<void> _downloadCard(RecentDesign design) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          Get.snackbar(
            'card_detail_permission_needed_title'.tr,
            'card_detail_save_permission_message'.tr,
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
        'card_detail_saved_title'.tr,
        'card_detail_saved_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } catch (e) {
      Get.snackbar(
        'card_detail_save_failed_title'.tr,
        'card_detail_save_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  void _editCard(RecentDesign design) {
    // AI generated cards re-open in the AI Card Generator with the card's
    // image already placed in the reference image section, so it can be
    // edited with AI again. Normal cards keep using the manual editor.
    if (design.isAiGenerated) {
      Get.to(() => AiCardGeneratorView(initialImage: design.file));
      return;
    }

    Get.to(() => CardEditorView(design: design));
  }

  Future<void> _deleteCard(BuildContext context, RecentDesign current) async {
    final ok = await showBlurredDialog<bool>(
      context,
      AppDialogCard(
        children: [
          const AppDialogIcon(Icons.delete_outline_rounded),
          const SizedBox(height: 18),
          AppDialogText(
            title: 'card_detail_delete_title'.tr,
            message: 'card_detail_delete_message'.tr,
          ),
          const SizedBox(height: 22),
          Builder(
            builder: (ctx) => AppDialogButton(
              label: 'card_detail_delete_confirm'.tr,
              color: const Color(0xFFD32F2F),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ),
          const SizedBox(height: 11),
          Builder(
            builder: (ctx) => AppDialogButton(
              label: 'custom_create_cancel'.tr,
              color: const Color(0xFF3A3A3C),
              onTap: () => Navigator.of(ctx).pop(false),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // The service forgets the card (and its pictures); My Cards and Home follow
    // it, so nothing has to be refreshed by hand.
    await Get.find<RecentDesignsService>().delete(current.id);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final service = Get.find<RecentDesignsService>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        // The card as it is NOW: editing it, or a change to the profile,
        // updates this screen too.
        child: Obx(() {
          final current = service.byId(design.id) ?? design;
          final downloadAction = onDownload ?? () => _downloadCard(current);
          final editAction = onEdit ?? () => _editCard(current);

          return Column(
            children: [
              // Back on the left, Delete on the right.
              CareerAppBar(
                title: '',
                trailing: TapTarget(
                  child: IconButton(
                    tooltip: 'card_detail_delete'.tr,
                    onPressed: () => _deleteCard(context, current),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 24,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      _DesignPreviewCard(file: current.file),
                      const SizedBox(height: 16),
                      _DesignPreviewCard(
                        file: current.backFile ?? current.file,
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
                        child: Text(
                          'card_detail_download'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (!current.isAiGenerated) ...[
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
                          child: Text(
                            'card_detail_edit'.tr,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
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
