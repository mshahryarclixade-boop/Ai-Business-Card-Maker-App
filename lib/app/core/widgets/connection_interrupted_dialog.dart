import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../theme/app_colors.dart';
import '../translations/tr_extension.dart';
import 'app_dialog.dart';

/// Shown when the connection drops mid-purchase.
Future<void> showConnectionInterruptedDialog() async {
  final context = Get.context;
  if (context == null || !context.mounted) return;
  await showBlurredDialog<void>(
    context,
    AppDialogCard(
      children: [
        const AppDialogIcon(Icons.wifi_off_rounded),
        const SizedBox(height: 18),
        AppDialogText(
          title: 'connection_interrupted_title'.tr,
          message: 'connection_interrupted_message'.tr,
        ),
        const SizedBox(height: 22),
        Builder(
          builder: (context) => AppDialogButton(
            label: 'credit_gate_ok'.tr,
            color: AppColors.accent,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    ),
  );
}
