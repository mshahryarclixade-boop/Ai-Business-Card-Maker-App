import 'dart:developer';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/widgets/app_dialog.dart';
import '../controller/credits_controller.dart';
import '../controller/subscription_controller.dart';
import '../view/paywall_screen.dart';
import 'user_credits_manager.dart';

/// Ported from face_swap's `CreditGate`: gates an action against the one
/// shared credit balance — every caller states what the action [cost]s
/// (see `RemoteConfigService().creditCosts`). Free users who run out are
/// offered the paywall; Pro users who used up their period's pool are told
/// when it refills. Everything passes while Remote Config's
/// `credits_enabled` is off.
///
/// Charges only for results actually delivered: check with [canUse] before
/// the request, [spend] after it succeeds — or wrap both with [run]. A
/// request that fails (API or server error, timeout, offline, the app
/// killed mid-request) is never charged, so nothing ever needs refunding.
/// Only a known balance that's too low shows "out of credits" / "limit
/// reached"; a balance that can't be read lets the action through.
///
/// Balances are initialized at startup and plan pools assigned by
/// RevenueCatHelper. Gated today: AI card generation and the template AI
/// fallback (`creditCosts.aiCard`), and card save/share exports
/// (`creditCosts.export`, 0 until Remote Config sets it).
///
/// Pass the same `dedupeKey` to [canUse] and [spend] for an action that
/// must be charged once per item (e.g. re-saving the same generated card):
/// once a key has been charged this session it passes free and is never
/// charged again.
abstract final class CreditGate {
  /// Swappable in tests.
  @visibleForTesting
  static bool Function() enabledProvider = () =>
      RemoteConfigService().creditsEnabled;

  /// The saved balance (null = unknown). Swappable in tests.
  @visibleForTesting
  static Future<int?> Function() balanceProvider = () =>
      UserCreditsManager().knownBalance();

  /// Swappable in tests.
  @visibleForTesting
  static Future<void> Function(int cost) deductProvider = (cost) async {
    await UserCreditsManager().deduct(cost);
  };

  static bool get enabled => enabledProvider();

  /// Keys already charged (or being charged) this session.
  static final Set<String> _charged = {};

  /// Forgets all charged keys — for tests.
  static void resetCharged() => _charged.clear();

  /// Runs [action] if the balance covers [cost], then charges [cost] only
  /// if it completed — when it throws, the error is passed on uncharged.
  /// Null when the user can't proceed (out of credits).
  static Future<T?> run<T>({
    required int cost,
    required String source,
    required Future<T> Function() action,
  }) async {
    if (!await canUse(cost: cost, source: source)) return null;
    final result = await action();
    await spend(cost: cost, source: source);
    return result;
  }

  /// True if the balance covers [cost] (or is unlimited, or can't be known),
  /// without deducting anything. Otherwise shows the out-of-credits dialog —
  /// for a free user, with an upgrade path; true after all if they subscribe
  /// there and the new pool covers it. [source] is the paywall's analytics
  /// source.
  static Future<bool> canUse({
    required int cost,
    required String source,
    String? dedupeKey,
  }) async {
    if (!enabled || cost <= 0) return true;
    if (dedupeKey != null && _charged.contains(dedupeKey)) return true;
    final credits = UserCreditsManager();
    final int? balance;
    try {
      balance = await balanceProvider();
    } catch (e) {
      // A storage/setup error isn't the user running out.
      log('balance check failed, allowing: $e', name: 'CreditGate');
      return true;
    }
    if (balance == null || balance == -1 || balance >= cost) return true;

    log('insufficient credits: have $balance, need $cost', name: 'CreditGate');
    // The live store state when it's there, else this device's saved flag
    // — never a Firestore round trip, which can stall the dialog offline.
    final isPro = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>().isPro
        : await credits.cachedIsPro();
    if (isPro) {
      await _showLimitDialog();
      return false;
    }
    if (!await _showOutOfCreditsDialog()) return false;
    await openPaywall(source: source);
    final after = await credits.getBalance();
    return after == -1 || after >= cost;
  }

  /// Charges [cost] for a result that was delivered. Call only after
  /// success — never before the request, and never for a failure. A
  /// failure to record the charge is logged, not shown: the user already
  /// has their result.
  static Future<void> spend({
    required int cost,
    required String source,
    String? dedupeKey,
  }) async {
    if (!enabled || cost <= 0) return;
    // Claimed before the await, so two overlapping calls charge once.
    if (dedupeKey != null && !_charged.add(dedupeKey)) return;
    try {
      await deductProvider(cost);
      CreditsController.bump();
      log('$cost credit(s) used ($source)', name: 'CreditGate');
    } catch (e) {
      // Not recorded as charged, so a later success can still be charged.
      if (dedupeKey != null) _charged.remove(dedupeKey);
      log('charge failed ($source): $e', name: 'CreditGate');
    }
  }

  static Future<void> _showLimitDialog() async {
    final context = Get.context;
    if (context == null || !context.mounted) return;
    await showBlurredDialog<void>(
      context,
      AppDialogCard(
        children: [
          const AppDialogIcon(Icons.lock_outline_rounded),
          const SizedBox(height: 18),
          AppDialogText(
            title: 'credit_gate_limit_reached_title'.tr,
            message: 'credit_gate_limit_reached_message'.tr,
          ),
          const SizedBox(height: 22),
          Builder(
            builder: (context) => AppDialogButton(
              label: 'credit_gate_ok'.tr,
              color: AppColors.accent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  /// True when the user chose Upgrade.
  static Future<bool> _showOutOfCreditsDialog() async {
    final context = Get.context;
    if (context == null || !context.mounted) return false;
    final upgrade = await showBlurredDialog<bool>(
      context,
      AppDialogCard(
        children: [
          const AppDialogIcon(Icons.bolt_rounded),
          const SizedBox(height: 18),
          AppDialogText(
            title: 'credit_gate_out_of_credits_title'.tr,
            message: 'credit_gate_out_of_credits_message'.tr,
          ),
          const SizedBox(height: 22),
          Builder(
            builder: (context) => AppDialogButton(
              label: 'credit_gate_upgrade'.tr,
              color: AppColors.accent,
              onTap: () => Navigator.of(context).pop(true),
            ),
          ),
          const SizedBox(height: 11),
          Builder(
            builder: (context) => AppDialogButton(
              label: 'credit_gate_not_now'.tr,
              color: const Color(0xFF3A3A3C),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ),
        ],
      ),
    );
    return upgrade ?? false;
  }
}
