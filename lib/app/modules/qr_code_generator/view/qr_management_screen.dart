import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
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

  void _open(QrEntry e) => Get.to(
    () => QrPreviewScreen(profile: e.profileData, style: e.style),
    transition: Transition.rightToLeft,
  );

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('qr_manage_delete_title'.tr),
        content: Text('qr_manage_delete_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('qr_manage_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'qr_manage_delete'.tr,
              style: const TextStyle(color: Colors.red),
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.titleDark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'qr_manage_title'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.titleDark,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        tooltip: 'qr_manage_new'.tr,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Obx(() {
        final list = QrStore.entries.toList();
        if (list.isEmpty) return const _Empty();
        final wide = MediaQuery.sizeOf(context).width >= 600;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
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
              onOpen: () => _open(e),
              onEdit: () => _edit(e),
              onDelete: () => _delete(context, e),
            );
          },
        );
      }),
    );
  }
}

enum _Action { open, edit, delete }

class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.entry,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final QrEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
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
                  _Action.open => onOpen(),
                  _Action.edit => onEdit(),
                  _Action.delete => onDelete(),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _Action.open,
                    child: Text('qr_manage_menu_open'.tr),
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
