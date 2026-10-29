import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../model/email_signature.dart';
import '../service/email_signature_store.dart';
import '../widgets/signature_card.dart';
import '../widgets/signature_sheets.dart';
import 'email_signature_editor_view.dart';

const savedRoute = '/EmailSignatureSaved';

final _frameKey = GlobalKey();

enum _CopyFormat { text, image }

/// "Add to your email": the signature to copy, and all the user's saved
/// signatures (use the menu to preview, edit or delete one).
class EmailSignatureSavedView extends StatelessWidget {
  const EmailSignatureSavedView({super.key});

  /// Leaves the module: pops every "/EmailSignature…" screen.
  void _done() =>
      Get.until((r) => !(r.settings.name ?? '').startsWith('/EmailSignature'));

  void _copiedSnack() => Get.snackbar(
    'email_sig_copied_title'.tr,
    'email_sig_copied_message'.tr,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(15),
    duration: const Duration(seconds: 2),
  );

  Future<void> _copyText(EmailSignature sig) async {
    await Clipboard.setData(
      ClipboardData(
        text: sig.toPlainText(
          madeWith: signatureIsPro() ? null : 'email_sig_made_with'.tr,
          bookCall: 'email_sig_book_button'.tr,
        ),
      ),
    );
    _copiedSnack();
  }

  Future<void> _copyImage() async {
    try {
      final boundary =
          _frameKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/signature.png');
      await file.writeAsBytes(data.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      Get.snackbar('email_signature_error_title'.tr, '$e');
    }
  }

  Future<void> _chooseCopy(BuildContext context, EmailSignature sig) async {
    final choice = await showModalBottomSheet<_CopyFormat>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'email_sig_copy_as'.tr,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.titleDark,
                ),
              ),
              const SizedBox(height: 12),
              _CopyOption(
                icon: Icons.text_fields_rounded,
                label: 'email_sig_copy_text'.tr,
                onTap: () => Navigator.pop(ctx, _CopyFormat.text),
              ),
              const SizedBox(height: 10),
              _CopyOption(
                icon: Icons.image_outlined,
                label: 'email_sig_copy_image'.tr,
                onTap: () => Navigator.pop(ctx, _CopyFormat.image),
              ),
            ],
          ),
        ),
      ),
    );
    switch (choice) {
      case _CopyFormat.text:
        await _copyText(sig);
      case _CopyFormat.image:
        await _copyImage();
      case null:
        break;
    }
  }

  void _preview(EmailSignature sig) => EmailSignatureStore.setActive(sig.id);

  void _edit(EmailSignature sig) => Get.to(
    () => EmailSignatureEditorView(existing: sig, fromSaved: true),
    routeName: editorRoute,
    transition: Transition.rightToLeft,
  );

  void _delete(EmailSignature sig) => EmailSignatureStore.remove(sig.id);

  void _new(BuildContext context) {
    void open() => Get.to(
      () => const EmailSignatureEditorView(fromSaved: true),
      routeName: editorRoute,
      transition: Transition.rightToLeft,
    );
    if (EmailSignatureStore.canCreate(isPro: signatureIsPro())) {
      open();
    } else {
      // Free plan: one signature. Going Pro lifts the limit.
      showSignatureUpgrade(
        context,
        title: 'email_sig_unlock_more'.tr,
        continueLabel: 'email_sig_pro_create'.tr,
        onUnlocked: open,
      );
    }
  }

  String _styleLabel(SignatureStyle s) => switch (s) {
    SignatureStyle.classic => 'email_sig_style_classic'.tr,
    SignatureStyle.compact => 'email_sig_style_compact'.tr,
    SignatureStyle.banner => 'email_sig_style_banner'.tr,
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              CareerAppBar(title: 'email_sig_saved_title'.tr, onLeading: _done),
              Expanded(
                child: Obx(() {
                  final pro = signatureIsPro();
                  final all = EmailSignatureStore.signatures.toList();
                  final active = EmailSignatureStore.active;
                  final canCreate = EmailSignatureStore.canCreate(isPro: pro);
                  return ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      8,
                      20,
                      16,
                    ),
                    children: [
                      if (active != null) ...[
                        RepaintBoundary(
                          key: _frameKey,
                          child: SignatureFrame(
                            sig: active,
                            madeWith: pro ? null : 'email_sig_made_with'.tr,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CareerPrimaryButton(
                          label: 'email_sig_copy'.tr,
                          icon: Icons.copy_rounded,
                          onTap: () => _chooseCopy(context, active),
                        ),
                        const SizedBox(height: 18),
                      ],
                      Text(
                        'email_sig_saved_list'.tr,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.titleDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.pillBorder),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < all.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  color: AppColors.pillBorder,
                                ),
                              _Row(
                                title: all[i].fullName,
                                subtitle: [
                                  _styleLabel(all[i].style),
                                  all[i].roleLine,
                                ].where((s) => s.isNotEmpty).join(' · '),
                                selected: all[i].id == active?.id,
                                onPreview: () => _preview(all[i]),
                                onEdit: () => _edit(all[i]),
                                onDelete: () => _delete(all[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NewRow(locked: !canCreate, onTap: () => _new(context)),
                    ],
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 14),
                child: CareerPrimaryButton(
                  label: 'email_sig_done'.tr,
                  onTap: _done,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RowAction { preview, edit, delete }

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _itemStyle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.titleDark,
  );

  PopupMenuItem<_RowAction> _item(
    _RowAction value,
    IconData icon,
    String label, {
    Color color = AppColors.titleDark,
  }) => PopupMenuItem<_RowAction>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: _itemStyle.copyWith(color: color)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? AppColors.onboardingBtnEnd
                  : AppColors.primarySoft,
            ),
            child: Icon(
              Icons.alternate_email_rounded,
              size: 17,
              color: selected ? Colors.white : AppColors.onboardingBtnEnd,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_RowAction>(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textGrey,
            ),
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (a) {
              switch (a) {
                case _RowAction.preview:
                  onPreview();
                case _RowAction.edit:
                  onEdit();
                case _RowAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (_) => [
              _item(
                _RowAction.preview,
                Icons.visibility_outlined,
                'email_sig_preview'.tr,
              ),
              _item(_RowAction.edit, Icons.edit_outlined, 'email_sig_edit'.tr),
              _item(
                _RowAction.delete,
                Icons.delete_outline_rounded,
                'email_sig_delete'.tr,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewRow extends StatelessWidget {
  const _NewRow({required this.locked, required this.onTap});

  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_rounded,
              size: 20,
              color: AppColors.onboardingBtnEnd,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'email_sig_new'.tr,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onboardingBtnEnd,
                ),
              ),
            ),
            if (locked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'email_sig_pro'.tr,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.crownGold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CopyOption extends StatelessWidget {
  const _CopyOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.onboardingBtnEnd),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.titleDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
