import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ---------------------------------------------------------------------------

const double _kDialogWidth = 332;
const double _kDialogMinHeight = 188;
const double _kDialogRadius = 24;
const double _kDialogSideMargin = 31; // (393 - 332) / 2
const EdgeInsets _kDialogPadding = EdgeInsets.fromLTRB(24, 20, 24, 20);
const double _kSectionGap = 24;

const double _kButtonWidth = 120;
const double _kButtonHeight = 32;
const double _kButtonRadius = 8;
const double _kButtonGap = 10;
// ---------------------------------------------------------------------------

class NoInternetDialog extends StatefulWidget {
  final Future<bool> Function() onRetry;
  final VoidCallback onClose;

  const NoInternetDialog({
    super.key,
    required this.onRetry,
    required this.onClose,
  });

  @override
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog> {
  bool _retrying = false;
  bool _stillOffline = false;

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _stillOffline = false;
    });

    final online = await widget.onRetry();

    if (!mounted) return;
    // If online, the service has already closed this dialog.
    if (!online) {
      setState(() {
        _retrying = false;
        _stillOffline = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen blur behind the card, like the reference design.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black.withOpacity(0.15),
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: _kDialogSideMargin),
            child: Container(
              // 332 wide (shrinks only if the screen is narrower).
              width: _kDialogWidth,
              // 188 tall; grows only if extra text (e.g. "Still no
              // connection") needs more room, so nothing overflows.
              constraints: const BoxConstraints(minHeight: _kDialogMinHeight),
              padding: _kDialogPadding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_kDialogRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 40,
                    color: AppColors.titleDark,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No Internet',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Please check your internet and try again',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF4A4A4A),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  if (_stillOffline) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Still no connection',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: Colors.redAccent,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                  const SizedBox(height: _kSectionGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: _kButtonWidth,
                        height: _kButtonHeight,
                        child: ElevatedButton(
                          onPressed: widget.onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F3F3),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(_kButtonRadius),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: _kButtonGap),
                      SizedBox(
                        width: _kButtonWidth,
                        height: _kButtonHeight,
                        child: ElevatedButton(
                          onPressed: _retrying ? null : _handleRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(_kButtonRadius),
                            ),
                          ),
                          child: _retrying
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Retry',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}