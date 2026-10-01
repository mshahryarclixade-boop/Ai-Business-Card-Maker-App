import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomColorPickerPopup extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final RxList<Color> savedColors;
  final ValueChanged<Color> onAddSavedColor;
  final VoidCallback onClose;

  const CustomColorPickerPopup({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    required this.savedColors,
    required this.onAddSavedColor,
    required this.onClose,
  });

  @override
  State<CustomColorPickerPopup> createState() =>
      _CustomColorPickerPopupState();
}

class _CustomColorPickerPopupState extends State<CustomColorPickerPopup> {
  late HSVColor _hsv;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _hexOf(_hsv.toColor()));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _hexOf(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

  void _applyColor(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _hexController.text = _hexOf(hsv.toColor());
    });
    widget.onColorChanged(hsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF15142B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: widget.onClose,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(Icons.close_rounded, size: 20, color: Colors.white70),
                  ),
                ),
              ),
            ),
            _HsvSquare(hsv: _hsv, onChanged: _applyColor),
            const SizedBox(height: 12),
            _HueBar(hue: _hsv.hue, onChanged: (h) => _applyColor(_hsv.withHue(h))),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Hex',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (v) {
                      final parsed = _tryParseHex(v);
                      if (parsed != null) _applyColor(HSVColor.fromColor(parsed));
                    },
                  ),
                ),
                const SizedBox(width: 6),
                // Note: a real eyedropper (sampling a color from the
                // screen/canvas) needs platform support that isn't wired
                // up yet — this currently just re-applies the typed hex.
                _RoundDarkButton(
                  icon: Icons.colorize_rounded,
                  onTap: () {
                    final parsed = _tryParseHex(_hexController.text);
                    if (parsed != null) _applyColor(HSVColor.fromColor(parsed));
                  },
                ),
                const SizedBox(width: 6),
                _RoundDarkButton(
                  icon: Icons.check_rounded,
                  onTap: () => widget.onAddSavedColor(color),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saved colors',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () => widget.onAddSavedColor(color),
                  child: const Text('+ Add',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(
                  () => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in widget.savedColors)
                    GestureDetector(
                      onTap: () => _applyColor(HSVColor.fromColor(c)),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration:
                        BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _tryParseHex(String input) {
    var hex = input.trim().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }
}

class _RoundDarkButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundDarkButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // _RoundDarkButton.build (check / eyedropper): the circle stays 26px,
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

/// Saturation/Value square. Horizontal = saturation, vertical = value
/// (inverted — top is bright).
class _HsvSquare extends StatelessWidget {
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;
  const _HsvSquare({required this.hsv, required this.onChanged});

  static const double _size = 232;

  void _handle(Offset local) {
    final dx = local.dx.clamp(0, _size) / _size;
    final dy = local.dy.clamp(0, _size) / _size;
    onChanged(hsv.withSaturation(dx).withValue(1 - dy));
  }

  @override
  Widget build(BuildContext context) {
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    return GestureDetector(
      onPanDown: (d) => _handle(d.localPosition),
      onPanUpdate: (d) => _handle(d.localPosition),
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(colors: [Colors.white, hueColor]),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
            Positioned(
              left: (hsv.saturation * _size) - 7,
              top: ((1 - hsv.value) * _size) - 7,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 4)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hue slider, 0–360.
class _HueBar extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;
  const _HueBar({required this.hue, required this.onChanged});

  static const double _height = 18;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        void handle(Offset local) {
          final ratio = (local.dx.clamp(0, width) / width);
          onChanged(ratio * 360);
        }

        return GestureDetector(
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          child: SizedBox(
            height: _height + 10,
            child: Stack(
              children: [
                Container(
                  height: _height,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_height / 2),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (hue / 360 * width) - 9,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 4)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}