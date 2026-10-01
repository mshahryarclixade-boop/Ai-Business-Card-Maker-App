import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'color_palette.dart';

class ColorChooserCard extends StatefulWidget {
  final Color? currentColor;
  final ValueChanged<Color> onSelectColor;
  final VoidCallback onOpenCustomPicker;
  final VoidCallback onCancel;
  final ValueChanged<Color?> onDone;

  const ColorChooserCard({
    super.key,
    required this.onSelectColor,
    required this.onOpenCustomPicker,
    required this.onCancel,
    required this.onDone,
    this.currentColor,
  });

  @override
  State<ColorChooserCard> createState() => _ColorChooserCardState();
}

class _ColorChooserCardState extends State<ColorChooserCard> {
  late TextEditingController _hexController;
  Color? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.currentColor;
    _hexController = TextEditingController(text: _hexOf(widget.currentColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _hexOf(Color? c) =>
      c == null ? '' : '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

  Color? _tryParseHex(String input) {
    var hex = input.trim().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose a color',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E24),
              ),
            ),
            const SizedBox(height: 18),
            ColorPaletteGrid(
              selected: _picked,
              swatchSize: 38,
              spacing: 18,
              onSelect: (c) {
                setState(() {
                  _picked = c;
                  _hexController.text = _hexOf(c);
                });
                widget.onSelectColor(c);
              },
              onOpenCustomPicker: widget.onOpenCustomPicker,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  'Hex',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    color: Color(0xFF6B6B72),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDDDDE3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDDDDE3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF1EEFC),
                      foregroundColor: const Color(0xFF4F4065),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final fromHex = _tryParseHex(_hexController.text);
                      widget.onDone(fromHex ?? _picked);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
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