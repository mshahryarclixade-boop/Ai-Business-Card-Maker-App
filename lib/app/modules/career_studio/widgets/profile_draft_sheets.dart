import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../paywall/view/paywall_screen.dart';
import 'career_widgets.dart';

/// "Edit headline" and friends: edit a generated text by hand. Resolves with
/// the new text on Save, or null on Cancel.
Future<String?> showEditTextSheet(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditSheet(title: title, initial: initial),
  );
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.title, required this.initial});
  final String title;
  final String initial;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              autofocus: true,
              minLines: 5,
              maxLines: 8,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                height: 1.4,
                color: AppColors.titleDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.scaffoldBg,
                contentPadding: const EdgeInsetsDirectional.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.pillBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.pillBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.onboardingBtnEnd,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _c,
                builder: (_, v, __) => Text(
                  'career_draft_characters'.trParams({
                    'count': v.text.characters.length,
                  }),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SheetButton(
                    label: 'career_draft_cancel'.tr,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetButton(
                    label: 'career_draft_save'.tr,
                    filled: true,
                    onTap: () => Navigator.of(context).pop(_c.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
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
      height: 50,
      child: Material(
        color: filled ? AppColors.onboardingBtnEnd : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
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
                  fontSize: 15,
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

/// "No AI rewrites left this month" (Free). [onEditMyself] opens the edit
/// sheet for the section the user tried to rewrite.
Future<void> showNoRewritesSheet(
  BuildContext context, {
  required VoidCallback onEditMyself,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'career_draft_no_rewrites_title'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'career_draft_no_rewrites_message'.tr,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textSubtitle,
              ),
            ),
            const SizedBox(height: 16),
            CareerPrimaryButton(
              label: 'career_draft_no_rewrites_upgrade'.tr,
              onTap: () {
                Navigator.of(ctx).pop();
                openPaywall(source: 'career_rewrite', plans: true);
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _SheetButton(
                label: 'career_draft_edit_myself'.tr,
                onTap: () {
                  Navigator.of(ctx).pop();
                  onEditMyself();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
