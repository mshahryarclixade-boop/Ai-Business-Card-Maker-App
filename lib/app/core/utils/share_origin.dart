import 'package:flutter/widgets.dart';

/// Anchor rectangle for the system share sheet. iOS needs a non-empty
/// `sharePositionOrigin` inside the app's window: without one share_plus
/// fails (on iPad always, and on newer iOS versions on iPhone too), so
/// every share call passes this.
///
/// Uses [context]'s widget when it is still on screen, otherwise a small
/// rectangle at the centre of the screen.
Rect shareOrigin([BuildContext? context]) {
  final box = context?.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize) {
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (!rect.isEmpty) return rect;
  }
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 2,
    height: 2,
  );
}
