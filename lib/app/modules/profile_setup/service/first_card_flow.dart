import 'dart:developer';

import 'package:flutter/foundation.dart' show debugPrint;
import '../../../core/services/notification_service.dart';
import '../../paywall/services/onboarding_experiment.dart';
import '../../paywall/services/paywall_triggers.dart';

/// What happens after the user picks "Scan a card" or "Share your card" on the
/// first-card screen:
///  1. the chosen action runs (the scan screen / the share sheet and its option);
///  2. when the user comes back from it, the paywall shows (the 50/50 test group
///     only, never to Pro, skippable);
///  3. when the paywall is closed, the notification permission dialog shows.
/// It runs ONCE: [begin] arms it, [afterAction] disarms it first thing.
abstract final class FirstCardFlow {
  static bool _armed = false;

  /// Armed between the tap on the first-card screen and the end of step 3. Home
  /// does not ask for notifications while it is armed (step 3 does).
  static bool get armed => _armed;

  static void begin() => _armed = true;

  /// Swappable in tests.
  static Future<void> Function() requestNotifications = () =>
      NotificationService().requestPermissionAndSubscribe();
  static bool Function() showsPaywall = () =>
      OnboardingExperiment().showsPaywall;
  static Future<void> Function() showPaywall = () => PaywallTriggers.show(
    PaywallTrigger.onboarding,
    screen: 'first_card_action',
  );

  static Future<void> afterAction() async {
    debugPrint('[paywall] afterAction reached, armed=$_armed');
    if (!_armed) return; // never twice
    _armed = false;
    try {
      final shows = showsPaywall();
      debugPrint('[paywall] first card: showsPaywall=$shows');
      if (shows) {
        await showPaywall();
      }
    } catch (e) {
      log('first card paywall failed: $e', name: 'FirstCardFlow');
    }
    await requestNotifications();
  }
}
