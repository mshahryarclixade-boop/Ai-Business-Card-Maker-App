import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/translations/tr_extension.dart';
import '../service/logo_background_remover.dart';
import 'checker_painter.dart';
import 'profile_primary_button.dart';

/// Offers to remove the background of a company logo.
///
/// Resolves to the transparent logo when the user applies it, or null when
/// they keep the original (or dismiss the sheet).
Future<Uint8List?> showLogoBackgroundSheet(
  BuildContext context,
  Uint8List original,
) {
  return showModalBottomSheet<Uint8List>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LogoBackgroundSheet(original: original),
  );
}

enum _Step { choose, working, preview }

class _LogoBackgroundSheet extends StatefulWidget {
  const _LogoBackgroundSheet({required this.original});

  final Uint8List original;

  @override
  State<_LogoBackgroundSheet> createState() => _LogoBackgroundSheetState();
}

class _LogoBackgroundSheetState extends State<_LogoBackgroundSheet> {
  _Step _step = _Step.choose;
  Uint8List? _processed;
  bool _failed = false;

  Future<void> _remove() async {
    setState(() {
      _step = _Step.working;
      _failed = false;
    });
    Uint8List? result;
    try {
      result = await LogoBackgroundRemover.remove(widget.original);
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    setState(() {
      _processed = result;
      _failed = result == null;
      _step = result == null ? _Step.choose : _Step.preview;
    });
  }

  void _keep() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final preview = _step == _Step.preview;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.splashBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.profileFieldBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (preview ? 'logo_bg_preview_title' : 'logo_bg_title').tr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.splashTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _failed
                        ? 'logo_bg_failed'.tr
                        : (preview
                                  ? 'logo_bg_preview_subtitle'
                                  : 'logo_bg_subtitle')
                              .tr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.splashTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Preview(
                    bytes: preview ? _processed! : widget.original,
                    checker: preview,
                    busy: _step == _Step.working,
                  ),
                  const SizedBox(height: 20),
                  if (preview) ...[
                    ProfilePrimaryButton(
                      label: 'logo_bg_apply'.tr,
                      showArrow: false,
                      onTap: () => Navigator.of(context).pop(_processed),
                    ),
                    const SizedBox(height: 8),
                    _SecondaryButton(label: 'logo_bg_keep'.tr, onTap: _keep),
                  ] else ...[
                    ProfilePrimaryButton(
                      label: 'logo_bg_remove'.tr,
                      showArrow: false,
                      onTap: _step == _Step.working ? () {} : _remove,
                    ),
                    const SizedBox(height: 8),
                    _SecondaryButton(
                      label: 'logo_bg_keep'.tr,
                      onTap: _step == _Step.working ? () {} : _keep,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.profileStepActive,
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.bytes,
    required this.checker,
    required this.busy,
  });

  final Uint8List bytes;

  /// Draw a checkerboard under the image so the transparency is visible.
  final bool checker;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.profileFieldBorder),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (checker) const CustomPaint(painter: CheckerPainter()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Opacity(
              opacity: busy ? 0.4 : 1,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
          if (busy)
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.profileStepActive,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
