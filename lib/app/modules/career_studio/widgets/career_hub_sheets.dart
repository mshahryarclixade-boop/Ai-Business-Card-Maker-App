import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../../paywall/services/revenue_cat_service.dart';
import '../../paywall/view/paywall_screen.dart';
import 'career_widgets.dart';

/// Bottom-sheet popups of the Career Studio hub. UI only.

Future<void> _show(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
          child: child,
        ),
      ),
    );

void _upgrade(BuildContext context, String source) {
  Navigator.of(context).pop();
  openPaywall(source: source, plans: true);
}

/// Post Planner is not built yet.
Future<void> showPostPlannerSoonSheet(BuildContext context) =>
    _show(context, const _PostPlannerSoon());

/// Starts a purchase of the chosen plan; true once the user is Pro.
typedef CareerPurchaser =
    Future<bool> Function(BuildContext context, {required bool yearly});

Future<bool> _buyPlan(BuildContext context, {required bool yearly}) =>
    Get.find<SubscriptionController>().buy(
      context,
      productId: yearly
          ? RevenueCatHelper.yearlyProductId
          : RevenueCatHelper.monthlyProductId,
      plan: yearly ? 'yearly' : 'monthly',
      source: 'career_studio',
    );

/// Upgrade to Pro. [lockedFeature] names the fix that was blocked ("Unlock
/// the “Featured” fix"). Continue buys the chosen plan (the store's own
/// confirmation appears), then "You're Pro" opens and its button runs
/// [onUnlocked] — the action the upgrade interrupted.
Future<void> showUpgradeSheet(
  BuildContext context, {
  String? lockedFeature,
  String? title,
  List<String>? perkKeys,
  String? proMessageKey,
  String? continueLabel,
  VoidCallback? onUnlocked,
  CareerPurchaser? purchaser,
}) async {
  final unlocked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
        child: _UpgradeSheet(
          lockedFeature: lockedFeature,
          title: title,
          perkKeys: perkKeys,
          purchaser: purchaser ?? _buyPlan,
        ),
      ),
    ),
  );
  if (unlocked == true && context.mounted) {
    await showYoureProDialog(
      context,
      buttonLabel: continueLabel ?? 'career_pro_continue'.tr,
      messageKey: proMessageKey,
      onContinue: onUnlocked,
    );
  }
}

/// "You're Pro": shown after a successful purchase.
Future<void> showYoureProDialog(
  BuildContext context, {
  required String buttonLabel,
  String? messageKey,
  VoidCallback? onContinue,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const FaIcon(
                FontAwesomeIcons.crown,
                size: 30,
                color: AppColors.crownGold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'career_pro_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (messageKey ?? 'career_pro_message').tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textSubtitle,
              ),
            ),
            const SizedBox(height: 18),
            CareerPrimaryButton(
              label: buttonLabel,
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
  onContinue?.call();
}

/// Free build used up.
Future<void> showBuildUsedSheet(
  BuildContext context, {
  required String resetDate,
  VoidCallback? onOpenDraft,
}) => _show(
  context,
  _UsedSheet(
    titleKey: 'career_hub_build_used_title',
    messageKey: 'career_hub_build_used_message',
    upgradeKey: 'career_hub_build_used_upgrade',
    openKey: 'career_hub_build_used_open',
    resetDate: resetDate,
    source: 'career_builder',
    onOpen: onOpenDraft,
  ),
);

/// Free scan used up.
Future<void> showScanUsedSheet(
  BuildContext context, {
  required String resetDate,
  VoidCallback? onOpenReport,
}) => _show(
  context,
  _UsedSheet(
    titleKey: 'career_hub_scan_used_title',
    messageKey: 'career_hub_scan_used_message',
    upgradeKey: 'career_hub_scan_used_upgrade',
    openKey: 'career_hub_scan_used_open',
    resetDate: resetDate,
    source: 'career_optimizer',
    onOpen: onOpenReport,
  ),
);

const _titleStyle = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 22,
  height: 1.2,
  fontWeight: FontWeight.w800,
  color: AppColors.titleDark,
);

const _bodyStyle = TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: 13.5,
  height: 1.4,
  color: AppColors.textSubtitle,
);

class _Check extends StatelessWidget {
  const _Check(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 2),
            child: Icon(
              Icons.check_rounded,
              size: 15,
              color: AppColors.onboardingBtnEnd,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: AppColors.titleDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.titleDark,
          side: const BorderSide(color: AppColors.pillBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.onboardingBtnEnd,
          ),
        ),
      ),
    );
  }
}

/// Small "we'll remind you" confirmation (no reminder backend yet).
void _acknowledge(BuildContext context, String messageKey) {
  Navigator.of(context).pop();
  Get.snackbar(
    'career_hub_reminder_title'.tr,
    messageKey.tr,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(15),
  );
}

// ---------------------------------------------------------------- CS04

class _PostPlannerSoon extends StatelessWidget {
  const _PostPlannerSoon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CareerComingSoonBadge(),
        const SizedBox(height: 10),
        Text('career_hub_post_planner_title'.tr, style: _titleStyle),
        const SizedBox(height: 12),
        _Check('career_hub_post_planner_perk_1'.tr),
        _Check('career_hub_post_planner_perk_2'.tr),
        _Check('career_hub_post_planner_perk_3'.tr),
        const SizedBox(height: 8),
        CareerPrimaryButton(
          label: 'career_hub_notify_button'.tr,
          onTap: () => _acknowledge(context, 'career_hub_notify_message'),
        ),
        _TextLink(
          label: 'career_hub_close'.tr,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Amber "COMING SOON" pill.
class CareerComingSoonBadge extends StatelessWidget {
  const CareerComingSoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1C7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'career_hub_coming_soon_badge'.tr,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8A6100),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- CS05

class _UpgradeSheet extends StatefulWidget {
  const _UpgradeSheet({
    required this.purchaser,
    this.lockedFeature,
    this.title,
    this.perkKeys,
  });

  final CareerPurchaser purchaser;
  final String? lockedFeature;

  /// Replaces the headline / the four perks (other features reuse the sheet).
  final String? title;
  final List<String>? perkKeys;

  @override
  State<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<_UpgradeSheet> {
  bool _yearly = true;
  bool _busy = false;

  Future<void> _continue() async {
    if (_busy) return;
    setState(() => _busy = true);
    var unlocked = false;
    try {
      unlocked = await widget.purchaser(context, yearly: _yearly);
    } catch (_) {
      unlocked = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (unlocked) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = RemoteConfigService().paywallConfig;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const FaIcon(
                FontAwesomeIcons.crown,
                size: 20,
                color: AppColors.crownGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'career_hub_upgrade_label'.tr,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.onboardingBtnEnd,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.title ??
                        (widget.lockedFeature == null
                            ? 'career_hub_upgrade_title'.tr
                            : 'career_hub_upgrade_title_feature'.trParams({
                                'feature': widget.lockedFeature,
                              })),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.titleDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final k
            in widget.perkKeys ??
                const [
                  'career_hub_upgrade_perk_1',
                  'career_hub_upgrade_perk_2',
                  'career_hub_upgrade_perk_3',
                  'career_hub_upgrade_perk_4',
                ])
          _Check(k.tr),
        const SizedBox(height: 6),
        _PlanTile(
          selected: _yearly,
          title: cfg.yearly.title,
          subtitle: 'career_hub_upgrade_yearly_note'.tr,
          price: '${cfg.yearly.price}${cfg.yearly.period}',
          onTap: () => setState(() => _yearly = true),
        ),
        const SizedBox(height: 8),
        _PlanTile(
          selected: !_yearly,
          title: cfg.monthly.title,
          subtitle: 'career_hub_upgrade_monthly_note'.tr,
          price: '${cfg.monthly.price}${cfg.monthly.period}',
          onTap: () => setState(() => _yearly = false),
        ),
        const SizedBox(height: 14),
        _busy
            ? const SizedBox(
                height: 54,
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.onboardingBtnEnd,
                    ),
                  ),
                ),
              )
            : CareerPrimaryButton(
                label: 'career_hub_upgrade_continue'.tr,
                onTap: _continue,
              ),
        _TextLink(
          label: 'career_hub_not_now'.tr,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.onboardingBtnEnd : AppColors.pillBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.onboardingBtnEnd
                      : AppColors.dotInactive,
                  width: selected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------- CS06 / CS07

class _UsedSheet extends StatelessWidget {
  const _UsedSheet({
    required this.titleKey,
    required this.messageKey,
    required this.upgradeKey,
    required this.openKey,
    required this.resetDate,
    required this.source,
    this.onOpen,
  });

  final String titleKey;
  final String messageKey;
  final String upgradeKey;
  final String openKey;
  final String resetDate;
  final String source;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titleKey.tr, style: _titleStyle),
        const SizedBox(height: 8),
        Text(messageKey.trParams({'date': resetDate}), style: _bodyStyle),
        const SizedBox(height: 16),
        CareerPrimaryButton(
          label: upgradeKey.tr,
          onTap: () => _upgrade(context, source),
        ),
        const SizedBox(height: 10),
        _OutlineButton(
          label: openKey.tr,
          onTap: () {
            Navigator.of(context).pop();
            onOpen?.call();
          },
        ),
        _TextLink(
          label: 'career_hub_remind_me'.trParams({'date': resetDate}),
          onTap: () => _acknowledge(context, 'career_hub_remind_message'),
        ),
      ],
    );
  }
}
