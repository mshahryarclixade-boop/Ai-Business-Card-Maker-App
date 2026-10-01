import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../custom_create/controller/card_editor_controller.dart';
import '../../custom_create/model/card_element_model.dart';
import '../../custom_create/view/card_editor_view.dart';

class CustomCreateCard extends StatelessWidget {
  const CustomCreateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openOrientationSheet(context),
      child: CustomPaint(
        // Draws the dashed border around the card.
        painter: _DashedBorderPainter(
          color: const Color(0x4444449A), // #44449466
          strokeWidth: 2,
          dashWidth: 4,
          dashGap: 4,
          radius: 16,
        ),
        child: Container(
          width: double.infinity,
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3FA),
            borderRadius: BorderRadius.circular(16),
          ),
          // Stack lets every element sit at the exact top/left offsets
          // from the Figma spec instead of relying on flex spacing.
          child: Stack(
            children: [
              // Large decorative placeholder circle on the left.
              const Positioned(
                left: 16,
                top: 16.33,
                child: _DecorativeCircle(size: 51),
              ),

              // Row 1 pill.
              const Positioned(
                left: 120,
                top: 26.33,
                child: _Pill(width: 130, height: 8),
              ),

              // Row 2 pill (long one).
              const Positioned(
                left: 120,
                top: 46.33,
                child: _Pill(width: 209, height: 8),
              ),

              // Row 3, split into two short pills.
              const Positioned(
                left: 214,
                top: 66.33,
                child: _Pill(width: 39, height: 8),
              ),
              const Positioned(
                left: 261,
                top: 66.33,
                child: _Pill(width: 68, height: 8),
              ),

              // "+" button, centered in the card.
              Positioned(
                left: (345 - 44) / 2,
                top: (130 - 44) / 2,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              // Italic caption, centered below the "+" button.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: Text(
                    'Start from a blank canvas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the "Choose Card Orientation" sheet. Used by the Custom Create
/// card AND by the Home screen's "new card" FAB, so both start the same flow.
void openOrientationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (_) => const _OrientationSheet(),
  );
}

// Decorative placeholder circle used at the left of the Custom Create card.
class _DecorativeCircle extends StatelessWidget {
  final double size;

  const _DecorativeCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0x99E9E9FE), // #E9E9FE99
        shape: BoxShape.circle,
      ),
    );
  }
}

// Decorative pill/bar used to mock text lines inside the Custom Create card.
class _Pill extends StatelessWidget {
  final double width;
  final double height;

  const _Pill({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x99E9E9FE), // #E9E9FE99
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}

class _OrientationSheet extends StatefulWidget {
  const _OrientationSheet();

  @override
  State<_OrientationSheet> createState() => _OrientationSheetState();
}

class _OrientationSheetState extends State<_OrientationSheet> {
  // Tracks which orientation is currently selected so the checkmark
  // and the "Start Designing" button know what to confirm.
  CardOrientation _selected = CardOrientation.landscape;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E1E6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Choose Card Orientation',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E24),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Select how your card will be laid out',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: AppColors.textSubtitle,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OrientationOption(
                      orientation: CardOrientation.landscape,
                      isSelected: _selected == CardOrientation.landscape,
                      onTap: () => setState(
                            () => _selected = CardOrientation.landscape,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _OrientationOption(
                      orientation: CardOrientation.portrait,
                      isSelected: _selected == CardOrientation.portrait,
                      onTap: () => setState(
                            () => _selected = CardOrientation.portrait,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Button now uses the available screen width instead of
              // a fixed width, so it adapts to smaller devices.
              SizedBox(
                width: double.infinity,
                height: 41,
                child: ElevatedButton(
                  onPressed: () => _choose(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Start Designing',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _choose(
      BuildContext context,
      CardOrientation orientation,
      ) {
    Navigator.of(context).pop();

    // Fresh controller per editing session so nothing leaks between cards.
    if (Get.isRegistered<CardEditorController>()) {
      Get.delete<CardEditorController>();
    }

    Get.put(
      CardEditorController(
        initialOrientation: orientation,
      ),
    );

    Get.to(
          () => const CardEditorView(),
      transition: Transition.rightToLeft,
    )?.then((_) {
      if (Get.isRegistered<CardEditorController>()) {
        Get.delete<CardEditorController>();
      }
    });
  }
}

class _OrientationOption extends StatelessWidget {
  final CardOrientation orientation;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrientationOption({
    required this.orientation,
    required this.isSelected,
    required this.onTap,
  });

  bool get _isPortrait => orientation == CardOrientation.portrait;

  // Dimension label shown below the orientation name, matching the design.
  String get _dimensionText => _isPortrait ? '2" x 3.5"' : '3.5" x 2"';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Framed card mockup, highlighted with the brand color and a
          // checkmark badge when this orientation is selected.
          Stack(
            clipBehavior: Clip.none,
            children: [
              AspectRatio(
                aspectRatio: _isPortrait ? (2 / 2.7) : (3.5 / 2.3),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFE1E1E6),
                      width: isSelected ? 1.6 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                        : null,
                  ),
                  child: _CardMockPreview(isPortrait: _isPortrait),
                ),
              ),

              // Selection checkmark shown on the top-right corner of the
              // frame for the currently chosen card.
              if (isSelected)
                Positioned(
                  top: -10,
                  right: -10,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 5),

          // Orientation name, highlighted in the brand color when selected.
          Text(
            orientation.label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppColors.primary : const Color(0xFF1E1E24),
            ),
          ),

          const SizedBox(height: 2),

          // Dimension text below the orientation name.
          Text(
            _dimensionText,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              color: AppColors.textSubtitle,
            ),
          ),

          const SizedBox(height: 4),

          // "Standard" badge.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F6EA),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check,
                  size: 12,
                  color: Color(0xFF1F9254),
                ),
                SizedBox(width: 4),
                Text(
                  'Standard',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F9254),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Miniature business-card preview ("Your Name" / "Job Title" / email)
// shown inside each orientation frame.
class _CardMockPreview extends StatelessWidget {
  final bool isPortrait;

  const _CardMockPreview({required this.isPortrait});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF17171F),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar circle shown above the details on portrait cards only.
          if (isPortrait) ...[
            const Center(
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
          ],

          const Text(
            'Your Name',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'Job Title',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10,
              color: Color(0xFFB5B5C3),
            ),
          ),

          const SizedBox(height: 6),

          // Decorative underline bar beneath the job title.
          Container(
            width: 40,
            height: 2.5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'youremail@gmail.com',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 8,
              color: Color(0xFF8E8E99),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint settings for the dashed border.
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Creates the rounded rectangle path.
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);

    // Converts the solid border path into a dashed path.
    final dashedPath = _dashPath(
      path,
      dashWidth,
      dashGap,
    );

    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(
      Path source,
      double dashWidth,
      double dashGap,
      ) {
    final Path dest = Path();

    for (final metric in source.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final next = distance + dashWidth;

        dest.addPath(
          metric.extractPath(
            distance,
            next.clamp(0, metric.length),
          ),
          Offset.zero,
        );

        distance = next + dashGap;
      }
    }

    return dest;
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) =>
      false;
}