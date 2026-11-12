import '../../../core/services/user_sync_service.dart';
import '../widgets/pro_dialogs.dart';

import '../../../core/services/remote_config_service.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'paywall_triggers.dart';
import 'usage_service.dart';

/// The glue the features use for the free plan's limits.
abstract final class FreeLimits {
  static UsageService get _usage => UsageService.to;

  /// The paywall trigger a feature opens when its free uses are gone.
  static PaywallTrigger limitTrigger(UsageFeature f) => switch (f) {
    UsageFeature.scan => PaywallTrigger.scanLimit,
    UsageFeature.aiCard => PaywallTrigger.aiLimit,
    UsageFeature.clixaChat => PaywallTrigger.clixaLimit,
    UsageFeature.careerBuild ||
    UsageFeature.careerOptimize ||
    UsageFeature.emailSignature => PaywallTrigger.crown,
  };

  /// Call BEFORE a new use. True: go ahead (Pro, or a free use is left).
  /// False: none is left - the feature's paywall was shown (the user keeps
  /// everything on screen: the prompt, the draft, the scan so far) and the
  /// user did not become Pro.
  static Future<bool> ensure(UsageFeature f, {String? screen}) async {
    // The counters live in Firestore: read them first (offline or slow: the
    // last known counts are used).
    await UserSync.refresh();
    if (_usage.canUse(f)) return true;
    final trigger = limitTrigger(f);
    if (!PaywallTriggers.enabled(trigger)) {
      // The paywall is switched off remotely: the limit still holds.
      showAppSnackbar('cro_limit_reached_title'.tr, 'cro_limit_reached_message'.tr);
      return false;
    }
    // Out of free AI cards: say so (the drafts stay saved) before the paywall.
    if (f == UsageFeature.aiCard && !await showAiLimitDialog()) return false;
    final pro = await PaywallTriggers.show(trigger, screen: screen);
    return pro;
  }

  /// The last free AI card was just made: the "You have used your free AI
  /// cards" dialog; See Pro opens the `ai_limit` paywall. The card, the prompt
  /// and the draft are untouched either way.
  static Future<void> promptAiLimit({String? screen}) async {
    if (!PaywallTriggers.enabled(PaywallTrigger.aiLimit)) return;
    if (!await showAiLimitDialog()) return;
    await PaywallTriggers.show(PaywallTrigger.aiLimit, screen: screen);
  }

  /// The second-last free scan: "1 free scan left". See Pro opens the
  /// `scan_warning` paywall; Keep scanning goes straight on (the scan result is
  /// held by the caller either way).
  static Future<void> promptScanWarning({String? screen}) async {
    if (!PaywallTriggers.enabled(PaywallTrigger.scanWarning)) return;
    final limit = _usage.limitOf(UsageFeature.scan);
    final used = _usage.used(UsageFeature.scan);
    final left = _usage.remaining(UsageFeature.scan);
    if (!await showScanLeftDialog(left: left, used: used, limit: limit)) return;
    await PaywallTriggers.show(PaywallTrigger.scanWarning, screen: screen);
  }

  /// "3 of 5 scans used" (null for Pro, or when counters are switched off).
  static String? counter(UsageFeature f) {
    if (_usage.isPro || !RemoteConfigService().croLimits.showCounters) return null;
    if (f == UsageFeature.emailSignature) return null; // no counter line
    final key = switch (f) {
      UsageFeature.scan => 'counter_scans',
      UsageFeature.aiCard => 'counter_ai',
      UsageFeature.clixaChat => 'counter_clixa',
      UsageFeature.careerBuild => 'counter_career_build',
      UsageFeature.careerOptimize => 'counter_career_optimize',
      UsageFeature.emailSignature => '',
    };
    return croText(
      key,
      params: {'used': _usage.used(f), 'limit': _usage.limitOf(f)},
    );
  }

  /// Pro templates can be previewed by everyone, but editing / applying one
  /// needs Pro. True: go ahead. False: the `pro_template` paywall was shown
  /// and the user did not become Pro (nothing on screen is lost).
  static Future<bool> ensureTemplate({
    required bool isPremium,
    PaywallTrigger trigger = PaywallTrigger.proTemplate,
    String? screen,
  }) async {
    if (!isPremium || _usage.isPro) return true;
    if (!PaywallTriggers.enabled(trigger)) return true;
    // "This QR style / template is Pro": the user decides before the paywall.
    final unlock = trigger == PaywallTrigger.proQr
        ? await showLockedQrDialog()
        : await showLockedTemplateDialog();
    if (!unlock) return false; // Maybe later: nothing is lost
    return PaywallTriggers.show(trigger, screen: screen);
  }
}
