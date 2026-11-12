import 'dart:async';
import 'dart:developer';

/// The slow part of app start (App Check, Remote Config, RevenueCat, the credit
/// record, the saved cards...) runs in the BACKGROUND after the first frame, so
/// the splash screen shows at once. The splash waits for [ready] only when it is
/// about to route (it animates for 3 s first, so normally nothing waits).
abstract final class AppStartup {
  static bool _started = false;
  static final _done = Completer<void>();

  /// Completes when [run]'s work has finished (or failed: the app then goes on
  /// with defaults). Already complete when nothing was started (tests).
  static Future<void> get ready => _started ? _done.future : Future<void>.value();

  static void run(Future<void> Function() work) {
    _started = true;
    work()
        .catchError((Object e, StackTrace s) => log('startup failed: $e', name: 'AppStartup', stackTrace: s))
        .whenComplete(() {
          if (!_done.isCompleted) _done.complete();
        });
  }
}
