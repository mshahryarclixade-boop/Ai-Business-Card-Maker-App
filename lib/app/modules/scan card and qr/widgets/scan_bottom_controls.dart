import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ScanBottomControls extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onCaptureTap;
  final VoidCallback onFlashTap;
  final bool isFlashOn;

  /// Hides the capture button's shutter icon in favour of a spinner while
  /// a photo is being processed.
  final bool isProcessing;

  const ScanBottomControls({
    super.key,
    required this.onGalleryTap,
    required this.onCaptureTap,
    required this.onFlashTap,
    this.isFlashOn = false,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(icon: Icons.photo_library_outlined, onTap: onGalleryTap),
        _CaptureButton(onTap: isProcessing ? null : onCaptureTap, isProcessing: isProcessing),
        _RoundButton(
          icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
          onTap: onFlashTap,
          active: isFlashOn,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _RoundButton({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isProcessing;

  const _CaptureButton({required this.onTap, this.isProcessing = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isProcessing
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
          )
              : Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
