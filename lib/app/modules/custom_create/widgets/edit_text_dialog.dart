import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/widgets/app_dialog.dart';

/// "Double tap to edit": the dialog that changes a text's words, in the same
/// style as the rest of the app's dialogs. Resolves to the new text, or null
/// when cancelled.
Future<String?> showEditTextDialog(BuildContext context, String current) {
  return showBlurredDialog<String>(context, _EditTextDialog(initial: current));
}

class _EditTextDialog extends StatefulWidget {
  const _EditTextDialog({required this.initial});

  final String initial;

  @override
  State<_EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<_EditTextDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  @override
  Widget build(BuildContext context) {
    // Lifts the dialog above the keyboard.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppDialogCard(
        children: [
          const AppDialogIcon(Icons.edit_note_rounded),
          const SizedBox(height: 16),
          Text(
            'custom_create_edit_text_title'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1C),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            cursorColor: AppColors.primary,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              color: Color(0xFF1C1C1C),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: _border(Colors.transparent),
              border: _border(Colors.transparent),
              focusedBorder: _border(AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DialogButton(
                  label: 'custom_create_cancel'.tr,
                  background: const Color(0xFFF1F1F4),
                  foreground: const Color(0xFF3A3A3C),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DialogButton(
                  label: 'custom_create_done'.tr,
                  background: AppColors.primary,
                  foreground: Colors.white,
                  onTap: () => Navigator.of(context).pop(_text.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
