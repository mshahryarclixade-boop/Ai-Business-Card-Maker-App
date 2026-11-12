import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/widgets/app_dialog.dart';

/// Which button closed a [showProDialog].
enum ProDialogChoice { primary, secondary, dismissed }

/// One contextual dialog at a time: a second request while one is open is
/// ignored (no stacked or repeated dialogs).
bool _open = false;

/// Tests end with dialogs still open; this clears the guard between them.
@visibleForTesting
void resetProDialogGuard() => _open = false;

/// The app's standard dialog (same card, icon and buttons as the permission and
/// connection dialogs) with a title, a body and one or two buttons.
Future<ProDialogChoice> showProDialog({
  required IconData icon,
  required String title,
  required String body,
  required String primary,
  String? secondary,
  bool barrierDismissible = true,
}) async {
  final ctx = Get.context;
  if (_open || ctx == null) return ProDialogChoice.dismissed;
  _open = true;
  try {
    final r = await showBlurredDialog<ProDialogChoice>(
      ctx,
      AppDialogCard(
        children: [
          AppDialogIcon(icon),
          const SizedBox(height: 18),
          AppDialogText(title: title, message: body),
          const SizedBox(height: 22),
          Builder(
            builder: (c) => AppDialogButton(
              label: primary,
              color: AppColors.primaryDark,
              onTap: () => Navigator.of(c).pop(ProDialogChoice.primary),
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(height: 11),
            Builder(
              builder: (c) => AppDialogButton(
                label: secondary,
                color: const Color(0xFF3A3A3C),
                onTap: () => Navigator.of(c).pop(ProDialogChoice.secondary),
              ),
            ),
          ],
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
    return r ?? ProDialogChoice.dismissed;
  } finally {
    _open = false;
  }
}

/// "1 free scan left". True: See Pro. False: Keep scanning.
Future<bool> showScanLeftDialog({
  required int left,
  required int used,
  required int limit,
}) async =>
    await showProDialog(
      icon: Icons.document_scanner_outlined,
      title: 'dlg_scan_left_title'.trParams({'left': left}),
      body: 'dlg_scan_left_body'.trParams({'used': used, 'limit': limit}),
      primary: 'dlg_see_pro'.tr,
      secondary: 'dlg_keep_scanning'.tr,
    ) ==
    ProDialogChoice.primary;

/// "You have used your free AI cards". True: See Pro.
Future<bool> showAiLimitDialog() async =>
    await showProDialog(
      icon: Icons.auto_awesome,
      title: 'dlg_ai_limit_title'.tr,
      body: 'dlg_ai_limit_body'.tr,
      primary: 'dlg_see_pro'.tr,
      secondary: 'dlg_not_now'.tr,
    ) ==
    ProDialogChoice.primary;

/// Before a free user saves or shares a card image: "Export without the
/// watermark?". Yes -> true; No (or dismissed) -> false.
Future<bool> showWatermarkExportDialog() async =>
    await showProDialog(
      icon: Icons.water_drop_outlined,
      title: 'dlg_watermark_export_title'.tr,
      body: 'dlg_watermark_export_body'.tr,
      primary: 'dlg_watermark_export_yes'.tr,
      secondary: 'dlg_watermark_export_no'.tr,
      barrierDismissible: false,
    ) ==
    ProDialogChoice.primary;

/// "This QR style is Pro". True: Unlock Pro.
Future<bool> showLockedQrDialog() async =>
    await showProDialog(
      icon: Icons.qr_code_2_rounded,
      title: 'dlg_qr_locked_title'.tr,
      body: 'dlg_qr_locked_body'.tr,
      primary: 'dlg_unlock_pro'.tr,
      secondary: 'dlg_maybe_later'.tr,
    ) ==
    ProDialogChoice.primary;

/// "This template is Pro". True: Unlock Pro.
Future<bool> showLockedTemplateDialog() async =>
    await showProDialog(
      icon: Icons.dashboard_customize_outlined,
      title: 'dlg_template_locked_title'.tr,
      body: 'dlg_template_locked_body'.tr,
      primary: 'dlg_unlock_pro'.tr,
      secondary: 'dlg_maybe_later'.tr,
    ) ==
    ProDialogChoice.primary;

/// "Your 3-day trial has started".
Future<void> showTrialStartedDialog(int days) => showProDialog(
  icon: Icons.verified_outlined,
  title: 'dlg_trial_title'.trParams({'days': days}),
  body: 'dlg_trial_body'.tr,
  primary: 'dlg_start_creating'.tr,
  barrierDismissible: false,
);

/// "Welcome to Pro".
Future<void> showWelcomeProDialog() => showProDialog(
  icon: Icons.verified_outlined,
  title: 'dlg_welcome_title'.tr,
  body: 'dlg_welcome_body'.tr,
  primary: 'dlg_start_creating'.tr,
  barrierDismissible: false,
);

/// "Purchases restored".
Future<void> showRestoredDialog() => showProDialog(
  icon: Icons.restore_rounded,
  title: 'dlg_restored_title'.tr,
  body: 'dlg_restored_body'.tr,
  primary: 'dlg_done'.tr,
);

/// "No purchases found".
Future<void> showNothingToRestoreDialog() => showProDialog(
  icon: Icons.search_off_rounded,
  title: 'dlg_nothing_title'.tr,
  body: 'dlg_nothing_body'.tr,
  primary: 'dlg_ok'.tr,
);
