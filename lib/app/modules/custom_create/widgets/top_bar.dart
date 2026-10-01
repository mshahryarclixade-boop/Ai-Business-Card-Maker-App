import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/card_editor_controller.dart';

const double _kDialogWidth = 332;
const double _kDialogMinHeight = 188;
const double _kDialogRadius = 24;
const double _kDialogSideMargin = 31; // (393 - 332) / 2
const EdgeInsets _kDialogPadding = EdgeInsets.fromLTRB(24, 20, 24, 20);
const double _kSectionGap = 24;

const double _kButtonWidth = 120;
const double _kButtonHeight = 32;
const double _kButtonRadius = 8;
const double _kButtonGap = 10;
// ---------------------------------------------------------------------------

class TopBar extends StatelessWidget {
  final CardEditorController controller;

  final GlobalKey repaintKey;

  const TopBar({
    super.key,
    required this.controller,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.topBarGradient,
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 18, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.white,
            ),
            onPressed: () => _confirmBack(context),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.35),
          ),
          const SizedBox(width: 14),
          Obx(
                () => BarIcon(
              icon: Icons.undo_rounded,
              enabled: controller.canUndo.value,
              onTap: controller.undo,
            ),
          ),
          const SizedBox(width: 16),
          Obx(
                () => BarIcon(
              icon: Icons.redo_rounded,
              enabled: controller.canRedo.value,
              onTap: controller.redo,
            ),
          ),
          const Spacer(),

          Obx(
                () => GestureDetector(
              onTap: controller.isSaving.value
                  ? null
                  : () => controller.save(repaintKey),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 2,
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBack(BuildContext context) {
    if (controller.elements.isEmpty) {
      Get.back();
      return;
    }
    showDialog(
      context: context,
      // Blur + dim is drawn by the dialog itself (same as NoInternetDialog),
      // so the default barrier is made transparent to avoid doubling up.
      barrierColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.15),
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: _kDialogSideMargin),
              child: Container(
                width: _kDialogWidth,
                constraints:
                const BoxConstraints(minHeight: _kDialogMinHeight),
                padding: _kDialogPadding,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_kDialogRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 40,
                      color: AppColors.titleDark,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Discard this card?',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titleDark,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Your changes will be lost if you leave now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4A5568),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: _kSectionGap),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: _kButtonWidth,
                          height: _kButtonHeight,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F3F3),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(_kButtonRadius),
                              ),
                            ),
                            child: const Text(
                              'Keep editing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: _kButtonGap),
                        SizedBox(
                          width: _kButtonWidth,
                          height: _kButtonHeight,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(_kButtonRadius),
                              ),
                            ),
                            child: const Text(
                              'Discard',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class BarIcon extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const BarIcon({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // BarIcon.build
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8 + 4),
        child: Icon(
          icon,
          size: 19,
          color: enabled ? Colors.white : Colors.white.withOpacity(0.35),
        ),
      ),
    );
  }
}