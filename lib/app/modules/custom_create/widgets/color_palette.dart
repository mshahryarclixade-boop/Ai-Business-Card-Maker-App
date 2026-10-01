import 'package:flutter/material.dart';

/// The single source of truth for every color swatch grid in the editor.
/// Both the Background tool and the Edit Text color tool import this so
/// they always show the exact same colors, in the exact same order.
const List<Color> kColorPalette = [
  Color(0xFFFF3B30),
  Color(0xFFFF9500),
  Color(0xFFFFCC00),
  Color(0xFF34C759),
  Color(0xFF00C7BE),
  Color(0xFF32ADE6),
  Color(0xFF007AFF),
  Color(0xFF5856D6),
  Color(0xFFAF52DE),
  Color(0xFFFF2D55),
  Color(0xFFA2845E),
  Color(0xFF8E8E93),
  Color(0xFFFFFFFF),
  Color(0xFF000000),
  Color(0xFFE1E1EE),
  Color(0xFFF5A623),
  Color(0xFFB5B5BD),
  Color(0xFF68686A),
  Color(0xFFD32F2F),
  Color(0xFF388E3C),
];

/// One plain solid-color swatch circle, with an optional "selected" ring.
class PaletteSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  const PaletteSwatch({
    super.key,
    required this.color,
    required this.onTap,
    this.selected = false,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xFF4F4065) : const Color(0xFFE1E1EE),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

/// The rainbow "multi-color" tile shown at the end of the grid in both
/// tools. Tapping it opens the full custom (HSV) color picker.
class MultiColorSwatch extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const MultiColorSwatch({super.key, this.size = 30, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFFFF3B30),
              Color(0xFFFFCC00),
              Color(0xFF34C759),
              Color(0xFF32ADE6),
              Color(0xFF5856D6),
              Color(0xFFAF52DE),
              Color(0xFFFF3B30),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full grid: every preset in [kColorPalette] plus the multi-color
/// tile at the end. Used by both the Background tool and the Edit Text
/// color tool so the two never drift apart again.
class ColorPaletteGrid extends StatelessWidget {
  final Color? selected;
  final ValueChanged<Color> onSelect;
  final VoidCallback onOpenCustomPicker;
  final double swatchSize;
  final double spacing;

  const ColorPaletteGrid({
    super.key,
    required this.onSelect,
    required this.onOpenCustomPicker,
    this.selected,
    this.swatchSize = 30,
    this.spacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final c in kColorPalette)
          PaletteSwatch(
            color: c,
            size: swatchSize,
            selected: selected != null && selected!.value == c.value,
            onTap: () => onSelect(c),
          ),
        MultiColorSwatch(size: swatchSize, onTap: onOpenCustomPicker),
      ],
    );
  }
}