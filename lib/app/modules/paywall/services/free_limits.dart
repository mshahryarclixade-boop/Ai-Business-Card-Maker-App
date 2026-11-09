import 'package:get/get.dart' hide Trans;

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
    UsageFeature.bgRemover => PaywallTrigger.proBg,
    UsageFeature.clixaChat => PaywallTrigger.clixaLimit,
    UsageFeature.careerBuild || UsageFeature.careerOptimize => PaywallTrigger.crown,
  };

  /// Call BEFORE a new use. True: go ahead (Pro, or a free use is left).
  /// False: none is left - the feature's paywall was shown (the user keeps
  /// everything on screen: the prompt, the draft, the scan so far) and the
  /// user did not become Pro.
  static Future<bool> ensure(UsageFeature f, {String? screen}) async {
    if (_usage.canUse(f)) return true;
    final trigger = limitTrigger(f);
    if (!PaywallTriggers.enabled(trigger)) {
      // The paywall is switched off remotely: the limit still holds.
      showAppSnackbar('cro_limit_reached_title'.tr, 'cro_limit_reached_message'.tr);
      return false;
    }
    final pro = await PaywallTriggers.show(trigger, screen: screen);
    return pro;
  }

  /// "3 of 5 scans used" (null for Pro, or when counters are switched off).
  static String? counter(UsageFeature f) {
    if (_usage.isPro || !RemoteConfigService().croLimits.showCounters) return null;
    final key = switch (f) {
      UsageFeature.scan => 'counter_scans',
      UsageFeature.aiCard => 'counter_ai',
      UsageFeature.bgRemover => 'counter_bg',
      UsageFeature.clixaChat => 'counter_clixa',
      UsageFeature.careerBuild => 'counter_career_build',
      UsageFeature.careerOptimize => 'counter_career_optimize',
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
    return PaywallTriggers.show(trigger, screen: screen);
  }
}
