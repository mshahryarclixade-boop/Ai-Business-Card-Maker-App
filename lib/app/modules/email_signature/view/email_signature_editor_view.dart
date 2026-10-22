import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../controller/signature_editor_controller.dart';
import '../model/email_signature.dart';
import '../service/email_signature_store.dart';
import '../widgets/signature_card.dart';
import '../widgets/signature_sheets.dart';
import 'email_signature_saved_view.dart';

const editorRoute = '/EmailSignatureEditor';

/// New / Edit signature: a live email preview, the details, the style and
/// what to show. [existing] edits a saved signature; null starts a new one
/// from the business card.
class EmailSignatureEditorView extends StatefulWidget {
  const EmailSignatureEditorView({
    super.key,
    this.existing,
    this.fromSaved = false,
  });

  final EmailSignature? existing;

  /// Opened from the saved signatures: saving just goes back to that screen.
  final bool fromSaved;

  @override
  State<EmailSignatureEditorView> createState() =>
      _EmailSignatureEditorViewState();
}

class _EmailSignatureEditorViewState extends State<EmailSignatureEditorView> {
  late final SignatureEditorController _c;
  late final String _tag;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _tag = 'sig_editor_${identityHashCode(this)}';
    _c = Get.put(
      SignatureEditorController(
        widget.existing ?? EmailSignatureStore.draftFromProfile(),
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    Get.delete<SignatureEditorController>(tag: _tag);
    super.dispose();
  }

  void _save() {
    _c.save();
    if (widget.fromSaved) {
      Navigator.of(context).pop();
      return;
    }
    Get.off(
      () => const EmailSignatureSavedView(),
      routeName: savedRoute,
      transition: Transition.rightToLeft,
    );
  }

  Future<void> _onBack() async {
    final choice = await showLeaveSignatureDialog(context);
    if (!mounted) return;
    switch (choice) {
      case LeaveChoice.discard:
        Navigator.of(context).pop();
      case LeaveChoice.save:
        _save();
      case LeaveChoice.keepEditing:
        break;
    }
  }

  Future<void> _editDetails() async {
    final r = await showSignatureDetailsSheet(context, _c.sig.value);
    if (r == null) return;
    _c.setDetails(
      fullName: r.fullName,
      jobTitle: r.jobTitle,
      company: r.company,
      phone: r.phone,
      website: r.website,
    );
  }

  void _pickStyle(SignatureStyle s) {
    if (s == SignatureStyle.banner && !signatureIsPro()) {
      showSignatureUpgrade(
        context,
        title: 'email_sig_unlock_banner'.tr,
        continueLabel: 'email_sig_pro_use_banner'.tr,
        onUnlocked: () => _c.setStyle(SignatureStyle.banner),
      );
      return;
    }
    _c.setStyle(s);
  }

  void _toggleBook(bool on) {
    if (on && !signatureIsPro()) {
      showSignatureUpgrade(
        context,
        title: 'email_sig_unlock_book'.tr,
        continueLabel: 'email_sig_pro_use_book'.tr,
        onUnlocked: () => _c.setBookCall(true),
      );
      return;
    }
    _c.setBookCall(on);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sig = _c.sig.value;
      final pro = signatureIsPro();
      return PopScope(
        // Unsaved changes: ask before leaving (arrow or system back).
        canPop: !_c.dirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onBack();
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          body: SafeArea(
            child: Column(
              children: [
                CareerAppBar(
                  title: _editing
                      ? 'email_sig_edit_title'.tr
                      : 'email_sig_new_title'.tr,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      8,
                      20,
                      16,
                    ),
                    children: [
                      _EmailPreview(sig: sig, showMadeWith: !pro),
                      const SizedBox(height: 12),
                      _DetailsCard(sig: sig, onEdit: _editDetails),
                      const SizedBox(height: 16),
                      _Heading('email_sig_style'.tr),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final s in SignatureStyle.values) ...[
                            if (s != SignatureStyle.classic)
                              const SizedBox(width: 8),
                            Expanded(
                              child: _StyleChip(
                                label: switch (s) {
                                  SignatureStyle.classic =>
                                    'email_sig_style_classic'.tr,
                                  SignatureStyle.compact =>
                                    'email_sig_style_compact'.tr,
                                  SignatureStyle.banner =>
                                    'email_sig_style_banner'.tr,
                                },
                                selected: sig.style == s,
                                pro: s == SignatureStyle.banner && !pro,
                                onTap: () => _pickStyle(s),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Heading('email_sig_show'.tr),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ImageTile(
                              label: 'email_sig_photo'.tr,
                              bytes: sig.photo,
                              fallback: Icons.person_rounded,
                              onPick: () => _c.pickImage(logo: false),
                              onRemove: () => _c.removeImage(logo: false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ImageTile(
                              label: 'email_sig_logo'.tr,
                              bytes: sig.logo,
                              fallback: Icons.business_rounded,
                              onPick: () => _c.pickImage(logo: true),
                              onRemove: () => _c.removeImage(logo: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ToggleTile(
                              label: 'email_sig_qr'.tr,
                              value: sig.showQr,
                              onChanged: _c.setQr,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ToggleTile(
                              label: 'email_sig_book'.tr,
                              value: sig.showBookCall && pro,
                              pro: !pro,
                              onChanged: _toggleBook,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.pillBorder),
                    ),
                  ),
                  child: CareerPrimaryButton(
                    label: 'email_sig_save'.tr,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// The signature inside a sample email (the sender's recipient, subject and
/// message are sample text).
class _EmailPreview extends StatelessWidget {
  const _EmailPreview({required this.sig, required this.showMadeWith});

  final EmailSignature sig;
  final bool showMadeWith;

  @override
  Widget build(BuildContext context) {
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              k,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                color: AppColors.textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.titleDark,
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('email_sig_to'.tr, 'email_sig_mail_to'.tr),
          row('email_sig_subject'.tr, 'email_sig_mail_subject'.tr),
          const Divider(height: 14, color: AppColors.pillBorder),
          Text(
            'email_sig_mail_body'.tr,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SignatureCard(sig: sig),
          ),
          if (showMadeWith) ...[
            const SizedBox(height: 8),
            Text(
              'email_sig_made_with'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                color: AppColors.textSubtitle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.sig, required this.onEdit});

  final EmailSignature sig;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final summary = [
      sig.fullName,
      sig.jobTitle,
      sig.phone,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.pillBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'email_sig_details'.tr,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.titleDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSubtitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.titleDark,
                side: const BorderSide(color: AppColors.pillBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                ),
              ),
              child: Text(
                'email_sig_edit'.tr,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 14.5,
      fontWeight: FontWeight.w800,
      color: AppColors.titleDark,
    ),
  );
}

class _ProTag extends StatelessWidget {
  const _ProTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      'email_sig_pro'.tr,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: AppColors.crownGold,
      ),
    ),
  );
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.pro = false,
  });

  final String label;
  final bool selected;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.onboardingBtnEnd : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: selected ? null : Border.all(color: AppColors.pillBorder),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.titleDark,
                ),
              ),
              if (pro) ...[const SizedBox(width: 5), const _ProTag()],
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo / Logo: tap to choose an image from the gallery.
class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.label,
    required this.bytes,
    required this.fallback,
    required this.onPick,
    required this.onRemove,
  });

  final String label;
  final Uint8List? bytes;
  final IconData fallback;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final has = bytes != null;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 68,
        padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: has ? AppColors.onboardingBtnEnd : AppColors.pillBorder,
            width: has ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primarySoft,
                image: has
                    ? DecorationImage(
                        image: MemoryImage(bytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: has
                  ? null
                  : Icon(fallback, size: 20, color: AppColors.onboardingBtnEnd),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                  Text(
                    (has ? 'email_sig_tap_to_change' : 'email_sig_tap_to_add')
                        .tr,
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
            if (has)
              IconButton(
                tooltip: 'email_sig_remove_image'.tr,
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textGrey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.pro = false,
  });

  final String label;
  final bool value;
  final bool pro;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 10, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.onboardingBtnEnd : AppColors.pillBorder,
            width: value ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleDark,
                ),
              ),
            ),
            if (pro)
              const _ProTag()
            else
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.onboardingBtnEnd,
                activeThumbColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      ),
    );
  }
}
