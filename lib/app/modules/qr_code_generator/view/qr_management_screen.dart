import '../../career_studio/widgets/career_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../contacts/widgets/contacts_fab.dart';
import '../model/qr_code_builder.dart';
import '../model/qr_entry.dart';
import '../service/qr_store.dart';
import '../widgets/styled_qr.dart';
import 'qr_code_screen.dart';
import 'qr_preview_screen.dart';

const qrManagementRoute = '/QrManagement';
const qrCreateRoute = '/QrCreate';

/// Home's QR button. The first time it opens the "Custom QR code" form; once a
/// code has been made it opens the saved QR codes instead.
void openQrCodes() {
  QrStore.load();
  if (QrStore.introSeen.value) {
    Get.to(
      () => const QrManagementScreen(),
      routeName: qrManagementRoute,
      transition: Transition.rightToLeft,
    );
  } else {
    Get.to(
      () => const CustomQrCodeScreen(),
      routeName: qrCreateRoute,
      transition: Transition.rightToLeft,
    );
  }
}

/// All the active profile's QR codes, each in its chosen style. The + button
/// makes another one.
class QrManagementScreen extends StatelessWidget {
  const QrManagementScreen({super.key});

  void _create() => Get.to(
    () => const CustomQrCodeScreen(fromManagement: true),
    routeName: qrCreateRoute,
    transition: Transition.rightToLeft,
  );

  /// Preview: this saved code becomes the one Home and "Show QR Code" show,
  /// and its own saved data and style are shown on the preview screen.
  void _preview(QrEntry e) {
    QrStore.select(e.id);
    Get.to(
      () => QrPreviewScreen(profile: e.profileData, style: e.style),
      transition: Transition.rightToLeft,
    );
  }

  void _edit(QrEntry e) => Get.to(
    () => CustomQrCodeScreen(
      fromManagement: true,
      initialForm: e.form,
      editId: e.id,
      initialStyleId: e.styleId,
    ),
    routeName: qrCreateRoute,
    transition: Transition.rightToLeft,
  );

  Future<void> _delete(BuildContext context, QrEntry e) async {
    final ok = await showBlurredDialog<bool>(
      context,
      AppDialogCard(
        children: [
          const AppDialogIcon(Icons.delete_outline_rounded),
          const SizedBox(height: 18),
          AppDialogText(
            title: 'qr_manage_delete_title'.tr,
            message: 'qr_manage_delete_message'.tr,
          ),
          const SizedBox(height: 22),
          Builder(
            builder: (ctx) => AppDialogButton(
              label: 'qr_manage_delete'.tr,
              color: const Color(0xFFD32F2F),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ),
          const SizedBox(height: 11),
          Builder(
            builder: (ctx) => AppDialogButton(
              label: 'qr_manage_cancel'.tr,
              color: const Color(0xFF3A3A3C),
              onTap: () => Navigator.of(ctx).pop(false),
            ),
          ),
        ],
      ),
    );
    if (ok == true) QrStore.remove(e.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // The same button as on Contacts (shape, size, right and bottom spacing).
      floatingActionButton: Tooltip(
        message: 'qr_manage_new'.tr,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 108),
          child: ContactsFab(onTap: _create),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CareerAppBar(title: 'qr_manage_title'.tr),
            Expanded(
              child: Obx(() {
                final list = QrStore.entries.toList();
                if (list.isEmpty) return const _Empty();
                final wide = MediaQuery.sizeOf(context).width >= 600;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 190),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wide ? 3 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final e = list[i];
                    return _QrCard(
                      entry: e,
                      onPreview: () => _preview(e),
                      onEdit: () => _edit(e),
                      onDelete: () => _delete(context, e),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Action { preview, edit, delete }

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.entry,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
  });

  final QrEntry entry;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPreview,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PopupMenuButton<_Action>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textGrey,
                ),
                padding: EdgeInsets.zero,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (a) => switch (a) {
                  _Action.preview => onPreview(),
                  _Action.edit => onEdit(),
                  _Action.delete => onDelete(),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _Action.preview,
                    child: Text('qr_manage_menu_preview'.tr),
                  ),
                  PopupMenuItem(
                    value: _Action.edit,
                    child: Text('qr_manage_menu_edit'.tr),
                  ),
                  PopupMenuItem(
                    value: _Action.delete,
                    child: Text(
                      'qr_manage_delete'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FittedBox(
                        child: StyledQr(
                          data: buildVCard(entry.profileData),
                          style: entry.style,
                          size: 160,
                          padding: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleDark,
                ),
              ),
            ),
            Text(
              entry.style.nameKey.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_2_rounded,
              size: 72,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 12),
            Text(
              'qr_manage_empty_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'qr_manage_empty_message'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
