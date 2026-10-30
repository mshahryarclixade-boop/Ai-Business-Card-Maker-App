import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Makes a small tappable widget (an icon button, a close "x") easy to hit:
/// taps up to [minSize] x [minSize] around it, centred on it, reach it.
///
/// Only the touch area grows. The child is laid out, sized and painted exactly
/// as before, so the icon keeps its look and nothing around it moves. Wrap the
/// whole tappable widget, e.g. `TapTarget(child: GestureDetector(...))`.
class TapTarget extends SingleChildRenderObjectWidget {
  const TapTarget({super.key, this.minSize = 48, super.child});

  /// The touch area's smallest side (Material's recommended minimum is 48).
  final double minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderTapTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, RenderTapTarget renderObject) {
    renderObject.minSize = minSize;
  }
}

class RenderTapTarget extends RenderProxyBox {
  RenderTapTarget(this._minSize);

  double _minSize;
  set minSize(double v) => _minSize = v;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) return super.hitTest(result, position: position);
    final dx = math.max(0.0, (_minSize - size.width) / 2);
    final dy = math.max(0.0, (_minSize - size.height) / 2);
    final reach = Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
    if (!reach.contains(position)) return false;
    // A tap in the extra area is handed to the child as a tap at its centre
    // (the icon itself; the child's own empty margins may not be hittable).
    return super.hitTest(result, position: size.center(Offset.zero));
  }
}
