import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_colors.dart';
import '../translations/tr_extension.dart';
import '../widgets/app_dialog.dart';

/// The permissions a feature can need before it runs.
enum AppPermission {
  camera(
    Permission.camera,
    Icons.photo_camera_outlined,
    'ai_card_permission_needed_title',
    'scan_camera_permission_needed',
  ),
  microphone(
    Permission.microphone,
    Icons.mic_none_rounded,
    'clixa_mic_denied_title',
    'clixa_mic_blocked_message',
  ),
  contacts(
    Permission.contacts,
    Icons.contacts_outlined,
    'contacts_permission_title',
    'contacts_permission_message',
  );

  const AppPermission(this.permission, this.icon, this.titleKey, this.messageKey);

  final Permission permission;
  final IconData icon;
  final String titleKey;
  final String messageKey;
}

/// Asks for a permission right before a feature needs it.
///
/// Granted: the feature goes ahead. Denied: a dialog offers "Open Settings"
/// (the app's page in the system settings) or "Later". Nothing is remembered:
/// each time the user tries the feature again and the permission is still
/// missing, it is asked for (or the dialog is shown) again, until it is
/// granted.
class PermissionGate {
  PermissionGate._();

  /// The system calls; replaced in tests.
  static Future<PermissionStatus> Function(Permission) statusOf = (p) =>
      p.status;
  static Future<PermissionStatus> Function(Permission) requestOf = (p) =>
      p.request();
  static Future<bool> Function() openSettings = openAppSettings;

  static bool _granted(PermissionStatus s) =>
      s.isGranted || s.isLimited || s.isProvisional;

  /// True when the system will not show its prompt again: the user can only
  /// change it in Settings.
  static bool _blocked(PermissionStatus s) =>
      s.isPermanentlyDenied || s.isRestricted;

  /// Asks for [p] with the system's Allow / Don't Allow prompt, if it can
  /// still be asked, without any dialog of ours. True when it is granted.
  static Future<bool> request(AppPermission p) async {
    var status = await statusOf(p.permission);
    if (_granted(status)) return true;
    if (_blocked(status)) return false;
    status = await requestOf(p.permission);
    return _granted(status);
  }

  /// First use: the system's Allow / Don't Allow prompt. If that is refused
  /// and the system will not ask again (iOS after one refusal, Android after
  /// two, or a restricted device), "Open Settings / Later" is shown. A
  /// refusal that can still be asked again shows nothing: the next try asks
  /// again. Returns true only when the permission is granted.
  static Future<bool> ensure(AppPermission p, {BuildContext? context}) async {
    if (await request(p)) return true;
    if (_blocked(await statusOf(p.permission))) {
      await showSettingsDialog(p, context: context);
    }
    return false;
  }

  /// Re-checks without asking (e.g. when the user comes back from Settings).
  static Future<bool> isGranted(AppPermission p) async =>
      _granted(await statusOf(p.permission));

  /// "Open Settings" / "Later". Returns true when the user chose Open Settings.
  static Future<bool> showSettingsDialog(
    AppPermission p, {
    BuildContext? context,
  }) async {
    final ctx = context ?? Get.context;
    if (ctx == null) return false;
    final open = await showBlurredDialog<bool>(
      ctx,
      AppDialogCard(
        children: [
          AppDialogIcon(p.icon),
          const SizedBox(height: 18),
          AppDialogText(title: p.titleKey.tr, message: p.messageKey.tr),
          const SizedBox(height: 22),
          Builder(
            builder: (c) => AppDialogButton(
              label: 'perm_open_settings'.tr,
              color: AppColors.primaryDark,
              onTap: () => Navigator.of(c).pop(true),
            ),
          ),
          const SizedBox(height: 11),
          Builder(
            builder: (c) => AppDialogButton(
              label: 'perm_later'.tr,
              color: const Color(0xFF3A3A3C),
              onTap: () => Navigator.of(c).pop(false),
            ),
          ),
        ],
      ),
    );
    if (open == true) {
      await openSettings();
      return true;
    }
    return false;
  }
}
