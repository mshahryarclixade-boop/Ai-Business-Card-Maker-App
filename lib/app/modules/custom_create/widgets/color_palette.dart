import 'package:flutter/material.dart';

/// The single source of truth for every color swatch grid in the editor.
/// The Background tool, the Edit Text color tool and the sticker color tool
/// all import this so they always show the exact same colors, in the exact
/// same order: vivid, soft tints, deep shades, then neutrals.
const List<Color> kColorPalette = [
  // Vivid
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
  // Soft tints
  Color(0xFFFFB3AE),
  Color(0xFFFFD3A1),
  Color(0xFFFFEE9E),
  Color(0xFFA9E8B8),
  Color(0xFF9BEDE8),
  Color(0xFFA6DBF4),
  Color(0xFF99C8FF),
  Color(0xFFBDBCEB),
  Color(0xFFDDB8F1),
  Color(0xFFFFABBC),
  // Deep shades
  Color(0xFFB3261E),
  Color(0xFFB35F00),
  Color(0xFFB38F00),
  Color(0xFF1F8F3C),
  Color(0xFF00857E),
  Color(0xFF1B6D96),
  Color(0xFF0048B3),
  Color(0xFF3A3991),
  Color(0xFF7A2F9B),
  Color(0xFFB31D3D),
  // Neutrals
  Color(0xFFFFFFFF),
  Color(0xFFF2F2F7),
  Color(0xFFE1E1EE),
  Color(0xFFB5B5BD),
  Color(0xFF8E8E93),
  Color(0xFF68686A),
  Color(0xFF2C2C2E),
  Color(0xFF000000),
  Color(0xFFA2845E),
];

const Color _ringDark = Color(0xFF4F4065);
const Color _hairline = Color(0xFFE1E1EE);

/// One solid-color swatch circle. Light colors get a visible hairline, and
/// the selected one a ring plus a tick that stays readable on any color.
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
    final light = color.computeLuminance() > 0.6;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? _ringDark : (light ? _hairline : Colors.white),
              width: selected ? 2.2 : 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  size: size * 0.55,
                  color: light ? _ringDark : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

/// The rainbow "multi-color" tile shown at the end of the grid. Tapping it
/// opens the full custom (HSV) color picker. The gradient runs through the
/// whole hue circle in small steps so it's smooth with no visible seam.
class MultiColorSwatch extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const MultiColorSwatch({super.key, this.size = 30, required this.onTap});

  static final List<Color> _spectrum = [
    for (var h = 0; h <= 360; h += 30)
      HSVColor.fromAHSV(1, h.toDouble() % 360, 0.9, 1).toColor(),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: _spectrum),
            border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          // A white centre makes it read as "pick any color".
          child: Center(
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The full grid: every preset in [kColorPalette] plus the multi-color tile
/// at the end, in even rows that fill the width (up to 10 across). Used by
/// the Background tool, the Edit Text color tool and the sticker tools so
/// they never drift apart.
class ColorPaletteGrid extends StatelessWidget {
  final Color? selected;
  final ValueChanged<Color> onSelect;
  final VoidCallback onOpenCustomPicker;

  /// The largest swatch; the grid shrinks swatches slightly to fit an even
  /// number per row.
  final double swatchSize;

  /// Kept for existing callers: the gap is now chosen by the grid.
  final double spacing;

  const ColorPaletteGrid({
    super.key,
    required this.onSelect,
    required this.onOpenCustomPicker,
    this.selected,
    this.swatchSize = 30,
    this.spacing = 14,
  });

  static const double _gap = 8;
  static const double _minSwatch = 24;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth.isFinite ? box.maxWidth : 340.0;
        final cols = ((width + _gap) / (_minSwatch + _gap)).floor().clamp(
          5,
          10,
        );
        // Rounded down so `cols` swatches always fit on one row.
        final size = ((width - _gap * (cols - 1)) / cols)
            .clamp(_minSwatch, swatchSize + 6)
            .floorToDouble();
        return Wrap(
          spacing: _gap,
          runSpacing: _gap + 2,
          children: [
            for (final c in kColorPalette)
              PaletteSwatch(
                color: c,
                size: size,
                selected:
                    selected != null && selected!.toARGB32() == c.toARGB32(),
                onTap: () => onSelect(c),
              ),
            MultiColorSwatch(size: size, onTap: onOpenCustomPicker),
          ],
        );
      },
    );
  }
}
