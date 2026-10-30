import 'package:flutter/painting.dart';

/// The look of a business card shown on its own over the page background:
/// a soft shadow that follows the card's edge. One definition, used by the
/// template previews and the card on Home, so they blend the same way.
const double kCardPreviewRadius = 1;

const List<BoxShadow> kCardPreviewShadow = [
  BoxShadow(
    color: Color(0x14000000), // black at 8%
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
];
