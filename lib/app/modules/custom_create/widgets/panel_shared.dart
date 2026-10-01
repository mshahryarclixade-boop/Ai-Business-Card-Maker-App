import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Small "← Title" row used at the top of every tool sub-panel.
class PanelHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const PanelHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: 40,
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              ),
            ),
          ),
        ),
        // const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E24),
          ),
        ),
      ],
    );
  }
}

/// White container with a top divider that every tool sub-panel sits in,
/// right above the bottom toolbar.
class PanelContainer extends StatelessWidget {
  final Widget child;
  const PanelContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDF2))),
      ),
      child: child,
    );
  }
}