import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'hide_when_pro.dart';

/// The small white circle with a gold crown that marks a Pro item (same look
/// as the template cards). Visual only - the item's own tap decides what
/// happens - and hidden for Pro users.
class ProCrownBadge extends StatelessWidget {
  const ProCrownBadge({super.key, this.iconSize = 12, this.padding = 5});

  final double iconSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return HideWhenPro(
      child: IgnorePointer(
        child: Container(
          key: const Key('pro_crown_badge'),
          padding: EdgeInsets.all(padding),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            FontAwesomeIcons.crown,
            size: iconSize,
            color: const Color(0xFFF5A623),
          ),
        ),
      ),
    );
  }
}
