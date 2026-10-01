// lib/app/core/widgets/rate_app_dialog.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Opens the "Happy With Our App?" dialog.
///
/// Not wired up anywhere yet. When ready, just call:
///
///   showRateAppDialog(
///     onYes: (rating) { /* e.g. open store review */ },
///     onNo: () { /* e.g. open feedback form */ },
///   );
Future<void> showRateAppDialog({
  ValueChanged<int>? onYes,
  VoidCallback? onNo,
  int initialRating = 4,
}) async {
  await Get.dialog<void>(
    RateAppDialog(
      onYes: onYes,
      onNo: onNo,
      initialRating: initialRating,
    ),
    barrierDismissible: false,
    useSafeArea: false, // lets the blur cover the status bar too
  );
}

class RateAppDialog extends StatefulWidget {
  /// Called after the dialog closes, with the selected star count (0–5).
  final ValueChanged<int>? onYes;
  final VoidCallback? onNo;

  /// 4 matches the design mockup. Use 0 for an empty starting state.
  final int initialRating;

  const RateAppDialog({
    super.key,
    this.onYes,
    this.onNo,
    this.initialRating = 4,
  });

  @override
  State<RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<RateAppDialog> {
  static const _starOn = Color(0xFFFFA62B);
  static const _starOff = Color(0xFFE6E6E8);
  static const _badgeSize = 72.0;

  late int _rating = widget.initialRating.clamp(0, 5);

  void _close() => Navigator.of(context, rootNavigator: true).pop();

  void _handleNo() {
    _close();
    widget.onNo?.call();
  }

  void _handleYes() {
    final rating = _rating;
    _close();
    widget.onYes?.call(rating);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency, // avoids the yellow text underline
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.15),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // ----- White card (starts halfway down the badge) -----
              Padding(
                padding: const EdgeInsets.only(top: _badgeSize / 2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, _badgeSize / 2 + 18, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Happy With Our App?',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.titleDark,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = i < _rating;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _rating = i + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                Icons.star_rounded,
                                size: 46,
                                color: filled ? _starOn : _starOff,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: _handleNo,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.titleDark,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'No',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _handleYes,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Yes',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ----- Star badge overlapping the top edge -----
              Container(
                width: _badgeSize,
                height: _badgeSize,
                padding: const EdgeInsets.all(8), // white ring around the badge
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6A5AE0), AppColors.primary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 30,
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