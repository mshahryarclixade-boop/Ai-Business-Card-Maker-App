import 'package:flutter/material.dart';

/// Widest the profile input / first card screens get on a tablet. Phones are
/// never wider than this, so they are unchanged.
const double kProfileSetupTabletMaxWidth = 640;

bool isProfileTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// A screen body: [scroll] fills the space above [footer]; both are centred
/// and limited to [kProfileSetupTabletMaxWidth].
///
/// [topBar] (back button + step header):
///  - phones: the first thing inside the scrolling content, followed by a
///    24px gap (exactly as before);
///  - tablets: pinned at the top of the screen, outside the scroll, while the
///    content below it is centred vertically when it is shorter than the
///    screen.
class ProfileSetupLayout extends StatelessWidget {
  const ProfileSetupLayout({
    super.key,
    required this.scroll,
    required this.footer,
    this.topBar,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    this.dismissKeyboardOnDrag = true,
  });

  final Widget scroll;
  final Widget footer;
  final Widget? topBar;
  final EdgeInsets padding;
  final bool dismissKeyboardOnDrag;

  @override
  Widget build(BuildContext context) {
    final tablet = isProfileTablet(context);

    // Phones: the top bar scrolls with the content, as it always did.
    final Widget content = (!tablet && topBar != null)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [topBar!, const SizedBox(height: 24), scroll],
          )
        : scroll;

    // Tablets get a little more room above the content, under the top bar.
    final scrollPadding = (tablet && topBar != null)
        ? padding.copyWith(top: 24)
        : padding;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: kProfileSetupTabletMaxWidth,
        ),
        child: Column(
          children: [
            if (tablet && topBar != null)
              Padding(
                padding: EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 0),
                child: SizedBox(width: double.infinity, child: topBar),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  keyboardDismissBehavior: dismissKeyboardOnDrag
                      ? ScrollViewKeyboardDismissBehavior.onDrag
                      : ScrollViewKeyboardDismissBehavior.manual,
                  padding: scrollPadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: c.maxHeight - scrollPadding.vertical,
                    ),
                    child: Align(
                      alignment: tablet
                          ? Alignment.center
                          : Alignment.topCenter,
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipe between the two profile input screens. Swiping towards the next
/// screen (left, or right in right-to-left languages) calls [onNext], the
/// other way calls [onPrevious]. A null callback means that way does nothing.
class ProfileSwipeNav extends StatelessWidget {
  const ProfileSwipeNav({
    super.key,
    required this.child,
    this.onNext,
    this.onPrevious,
  });

  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  /// Fast enough to be a swipe and not a slow drag (logical px / second).
  static const double minVelocity = 350;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() < minVelocity) return;
        final towardsNext = rtl ? v > 0 : v < 0;
        (towardsNext ? onNext : onPrevious)?.call();
      },
      child: child,
    );
  }
}