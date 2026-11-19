import 'package:flutter/foundation.dart' show VoidCallback, debugPrint;
import 'package:get/get.dart' hide Trans;

import '../../../core/services/remote_config_service.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/subscription_controller.dart';
import '../view/paywall_screen.dart';

/// The CRO plan's paywall triggers, each with its source tag (analytics).
enum PaywallTrigger {
  /// First card ready, before "Go to Home": skippable, X visible at once.
  onboarding('onboarding', plans: true, skippable: true),

  /// The second-last free scan: skippable warning.
  scanWarning(
    'scan_warning',
    plans: true,
    skippable: true,
    headline: 'scan_limit_headline',
  ),

  /// No free scan left.
  scanLimit('scan_limit', plans: true, headline: 'scan_limit_headline'),

  /// The last free AI card was made, or none is left.
  aiLimit('ai_limit', plans: true, headline: 'ai_limit_headline'),

  proTemplate('pro_template', plans: true, headline: 'pro_template_headline'),
  proQr('pro_qr', plans: true, headline: 'pro_qr_headline'),

  /// "Remove watermark" on the export screen.
  watermark('watermark', plans: true, headline: 'watermark_headline'),

  /// Clixa chat limit.
  clixaLimit('clixa_limit', plans: true, headline: 'clixa_limit_headline'),

  /// Any crown button (Home first).
  crown('crown', plans: true),

  /// Settings "Get Pro".
  settings('settings', plans: true);

  const PaywallTrigger(
    this.source, {
    required this.plans,
    this.skippable = false,
    this.headline,
  });

  /// The source tag: what analytics and the purchase events carry.
  final String source;

  /// Opens the screen with both plans straight away (else the yearly pitch).
  final bool plans;
  final bool skippable;

  /// Key of the trigger's own headline in `cro_messages` (else the default).
  final String? headline;
}

/// Text from `cro_messages`: the default in the app language, or what Remote
/// Config changed it to, written as is.
String croText(String key, {Map<String, Object> params = const {}}) {
  final messages = RemoteConfigService().croMessages;
  var s = messages.overridden(key) ? messages.text(key) : 'cro_msg_$key'.tr;
  params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// The one place that opens the paywall for the plan's triggers.
abstract final class PaywallTriggers {
  static bool get _isPro =>
      Get.isRegistered<SubscriptionController>() &&
      Get.find<SubscriptionController>().isPro;

  /// Whether Remote Config has this trigger on.
  static bool enabled(PaywallTrigger t) =>
      RemoteConfigService().croTriggers.enabled(t.source);

  /// Opens the paywall for [t]. Returns true when the user is Pro afterwards
  /// (Pro never sees a paywall; a trigger Remote Config switched off shows
  /// none and returns false).
  static Future<bool> show(PaywallTrigger t, {String? screen}) async {
    if (_isPro) {
      debugPrint('[paywall] ${t.source}: skipped, user is Pro');
      return true;
    }
    if (!enabled(t)) {
      debugPrint('[paywall] ${t.source}: skipped, trigger off in Remote Config');
      return false;
    }
    debugPrint('[paywall] ${t.source}: opening paywall');
    return openPaywall(
      source: t.source,
      plans: t.plans,
      // Remote Config's paywall_config.headlines first, else the built-in
      // (translated) headline.
      headlineBuilder: () =>
          RemoteConfigService().paywallConfig.headlineFor(
            t.source,
            generic: t.headline == null,
          ) ??
          croText(t.headline ?? 'default_headline'),
      skippable: t.skippable,
      screen: screen,
    );
  }
}

/// Every Pro icon / lock that is not a plan trigger opens the plans paywall
/// (Paywall View 2) with its own [source]. When the user ends up Pro,
/// [onUnlocked] runs - the action the upgrade interrupted. (Only the Expert
/// panel's crown keeps its own Pro sheet.)
Future<bool> openProPaywall(
  String source, {
  String? screen,
  VoidCallback? onUnlocked,
}) async {
  final pro = await openPaywall(source: source, plans: true, screen: screen);
  if (pro) onUnlocked?.call();
  return pro;
}
