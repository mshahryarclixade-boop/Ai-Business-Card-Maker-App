import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../career_studio/widgets/career_hub_sheets.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../../paywall/services/revenue_cat_service.dart';
import '../model/email_signature.dart';

/// Whether the user has Pro right now (observable inside an Obx).
bool signatureIsPro() =>
    Get.isRegistered<SubscriptionController>() &&
    Get.find<SubscriptionController>().isUserPro.value;

Future<bool> _buy(BuildContext context, {required bool yearly}) =>
    Get.find<SubscriptionController>().buy(
      context,
      productId: yearly
          ? RevenueCatHelper.yearlyProductId
          : RevenueCatHelper.monthlyProductId,
      plan: yearly ? 'yearly' : 'monthly',
      source: 'email_signature',
    );

/// "Go Pro" for a locked signature option. After a purchase, "You're Pro"
/// opens and its button runs [onUnlocked].
Future<void> showSignatureUpgrade(
  BuildContext context, {
  required String title,
  required String continueLabel,
  required VoidCallback onUnlocked,
}) => showUpgradeSheet(
  context,
  title: title,
  perkKeys: const [
    'email_sig_perk_1',
    'email_sig_perk_2',
    'email_sig_perk_3',
    'email_sig_perk_4',
  ],
  proMessageKey: 'email_sig_pro_message',
  continueLabel: continueLabel,
  onUnlocked: onUnlocked,
  purchaser: _buy,
);

/// What the user chose when leaving the editor with unsaved changes.
enum LeaveChoice { discard, save, keepEditing }

Future<LeaveChoice> showLeaveSignatureDialog(BuildContext context) async {
  final r = await showDialog<LeaveChoice>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'email_sig_leave_title'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'email_sig_leave_message'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSubtitle,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SigButton(
                    label: 'email_sig_discard'.tr,
                    onTap: () => Navigator.of(ctx).pop(LeaveChoice.discard),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SigButton(
                    label: 'email_sig_leave_save'.tr,
                    filled: true,
                    onTap: () => Navigator.of(ctx).pop(LeaveChoice.save),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(LeaveChoice.keepEditing),
                child: Text(
                  'email_sig_keep_editing'.tr,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onboardingBtnEnd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return r ?? LeaveChoice.keepEditing; // tapped outside
}

/// "Your details" sheet. Returns the edited signature, or null on Cancel.
Future<EmailSignature?> showSignatureDetailsSheet(
  BuildContext context,
  EmailSignature sig,
) {
  return showModalBottomSheet<EmailSignature>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _DetailsSheet(sig: sig),
  );
}

class _DetailsSheet extends StatefulWidget {
  const _DetailsSheet({required this.sig});
  final EmailSignature sig;

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  late final _name = TextEditingController(text: widget.sig.fullName);
  late final _job = TextEditingController(text: widget.sig.jobTitle);
  late final _company = TextEditingController(text: widget.sig.company);
  late final _phone = TextEditingController(text: widget.sig.phone);
  late final _website = TextEditingController(text: widget.sig.website);

  @override
  void dispose() {
    _name.dispose();
    _job.dispose();
    _company.dispose();
    _phone.dispose();
    _website.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return; // a signature needs a name
    Navigator.of(context).pop(
      widget.sig.copyWith(
        fullName: _name.text.trim(),
        jobTitle: _job.text.trim(),
        company: _company.text.trim(),
        phone: _phone.text.trim(),
        website: _website.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'email_sig_sheet_title'.tr,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.titleDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'email_sig_sheet_message'.tr,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textSubtitle,
                ),
              ),
              const SizedBox(height: 14),
              _Field('email_sig_field_name'.tr, _name),
              _Field('email_sig_field_job'.tr, _job),
              _Field('email_sig_field_company'.tr, _company),
              _Field(
                'email_sig_field_phone'.tr,
                _phone,
                type: TextInputType.phone,
              ),
              _Field(
                'email_sig_field_website'.tr,
                _website,
                type: TextInputType.url,
                last: true,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SigButton(
                      label: 'email_sig_cancel'.tr,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SigButton(
                      label: 'email_sig_sheet_save'.tr,
                      filled: true,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.controller, {this.type, this.last = false});

  final String label;
  final TextEditingController controller;
  final TextInputType? type;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: type,
            textInputAction: last ? TextInputAction.done : TextInputAction.next,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              color: AppColors.titleDark,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.scaffoldBg,
              isDense: true,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.pillBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.pillBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.onboardingBtnEnd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded dialog / sheet button (outlined, or filled blue).
class SigButton extends StatelessWidget {
  const SigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Material(
        color: filled ? AppColors.onboardingBtnEnd : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: filled ? null : Border.all(color: AppColors.pillBorder),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : AppColors.titleDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
