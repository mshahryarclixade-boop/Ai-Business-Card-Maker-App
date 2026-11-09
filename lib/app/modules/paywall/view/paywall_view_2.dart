import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/utils/legal_links.dart';
import '../controller/subscription_controller.dart';
import '../models/paywall_config_model.dart';
import '../widgets/paywall_canvas.dart';
import 'paywall_actions.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const double _kDesignWidth = 393;
const double _kDesignHeight = 860;

class PaywallView2 extends StatefulWidget {
  const PaywallView2({super.key, this.pops = 2});

  /// Screens closed on leaving: 2 when opened from the first paywall
  /// screen (both close), 1 when opened directly.
  final int pops;

  @override
  State<PaywallView2> createState() => _PaywallView2State();
}

class _PaywallView2State extends State<PaywallView2> {
  /// `monthly` or `yearly` — the plan Continue purchases.
  String _selected = 'yearly';

  @override
  Widget build(BuildContext context) => Obx(() {
    // Rebuilt once the store products (real prices) load.
    Get.find<SubscriptionController>().products.length;
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final cfg = RemoteConfigService().paywallConfig;
    // A hidden monthly plan can't stay selected.
    final selected = cfg.monthly.visible ? _selected : 'yearly';
    // Tablets get a real responsive layout (content ~88% wide with a maximum
    // width), not the phone canvas blown up.
    if (MediaQuery.sizeOf(context).shortestSide >= 600) {
      return _TabletPaywall(
        cfg: cfg,
        selected: selected,
        pops: widget.pops,
        onSelect: (plan) => setState(() => _selected = plan),
      );
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _kBackgroundGradient),
        child: SafeArea(
          child: PaywallCanvas(
            designWidth: _kDesignWidth,
            designHeight: _kDesignHeight,
            child: Stack(
              children: [
                const _Artwork(),
                if (cfg.showCloseButton || PaywallActions.skippable)
                  _CloseButton(pops: widget.pops),
                _Headline(cfg),
                _Subtitle(cfg),
                _FeaturePills(cfg),
                _PlanCardsRow(
                  cfg,
                  selected: selected,
                  onSelect: (plan) => setState(() => _selected = plan),
                ),
                _ContinueButton(cfg, selected: selected, pops: widget.pops),
                _CommitmentText(cfg, selected: selected),
                _Footer(cfg, pops: widget.pops),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BACKGROUND
// -----------------------------------------------------------------------------

// background: linear-gradient(168.85deg, #DAD5FB 1.09%, #F6F3FC 50.19%, #E0E0FF 99.3%);
const LinearGradient _kBackgroundGradient = LinearGradient(
  begin: Alignment(-0.193, -0.981),
  end: Alignment(0.193, 0.981),
  colors: [Color(0xFFDAD5FB), Color(0xFFF6F3FC), Color(0xFFE0E0FF)],
  stops: [0.0109, 0.5019, 0.993],
);

// -----------------------------------------------------------------------------
// CLOSE BUTTON
// -----------------------------------------------------------------------------

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.pops});
  final int pops;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 20,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => PaywallActions.close(context, pops: pops),
        // A 44px touch target around a clearly visible 34px X.
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFD9D7EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 22,
              color: Color(0xFF1F1F2E),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ARTWORK — cards image + decorative icon badges + sparkles layered on top,
// same approach as PaywallView's _ArtworkCards.
// -----------------------------------------------------------------------------

class _Artwork extends StatelessWidget {
  const _Artwork();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 20,
      left: 0,
      width: 393,
      height: 210,
      child: Stack(
        children: [
          // // The two business cards themselves.
          Positioned(
            top: 30,
            left: 88,
            width: 220,
            height: 170,
            child: Image(
              image: AssetImage('assets/icons/paywall2.png'),
              fit: BoxFit.contain,
            ),
          ),

          // Sparkles scattered around the cards.
          Positioned(
            top: 35,
            left: 120,
            child: Icon(Icons.auto_awesome, size: 14, color: Color(0xFFAA96FA)),
          ),
          Positioned(
            top: 20,
            left: 255,
            child: Icon(Icons.auto_awesome, size: 12, color: Colors.white),
          ),
          Positioned(
            top: 45,
            left: 290,
            child: Icon(Icons.auto_awesome, size: 16, color: Color(0xFF7658E8)),
          ),
          Positioned(
            top: 115,
            left: 80,
            child: Icon(Icons.auto_awesome, size: 10, color: Colors.white),
          ),
          Positioned(
            top: 125,
            left: 300,
            child: Icon(Icons.auto_awesome, size: 12, color: Colors.white),
          ),

          // Top-left badge — "AI".
          _IconBadge(top: 60, left: 70, icon: Icons.memory_rounded),

          // Top-right badge — scan/squiggle.
          _IconBadge(top: 78, left: 296, icon: Icons.gesture_rounded),

          // Bottom-left badge — templates/grid.
          _IconBadge(top: 128, left: 50, icon: Icons.grid_view_rounded),

          // Bottom-right badge — QR code.
          _IconBadge(top: 140, left: 300, icon: Icons.qr_code_2_rounded),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final double top;
  final double left;
  final IconData icon;

  const _IconBadge({required this.top, required this.left, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HEADLINE — "Create and scan without limits" (or the trigger's own)
// -----------------------------------------------------------------------------

class _Headline extends StatelessWidget {
  const _Headline(this.cfg);
  final PaywallConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 225,
      left: (393 - 320) / 2,
      width: 320,
      child: Text(
        PaywallActions.headline ?? cfg.s2Title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: AppColors.titleDark,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUBTITLE
// -----------------------------------------------------------------------------

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.cfg);
  final PaywallConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 290,
      left: 46.5,
      width: 300,
      child: Text(
        cfg.s2Subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textTitle,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FEATURE PILLS — 3 rows x 2 columns
// -----------------------------------------------------------------------------

class _FeaturePills extends StatelessWidget {
  const _FeaturePills(this.cfg);
  final PaywallConfig cfg;

  @override
  Widget build(BuildContext context) {
    final items = cfg.s2Features;
    return Positioned(
      top: 326,
      left: 24,
      width: 345,
      // The pills flow and centre: a long translation wraps to the next line
      // instead of being cut off.
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [for (final t in items) _PillBadge(text: t)],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String text;

  const _PillBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 345),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBody,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PLAN CARDS — Monthly (unselected) + Yearly (selected, "Most Popular")
// -----------------------------------------------------------------------------

const Color _kSaveGreen = Color(0xFF2AA96B);
const Color _kSaveGreenBg = Color(0xFFE3F6EC);

class _PlanCardsRow extends StatelessWidget {
  const _PlanCardsRow(
    this.cfg, {
    required this.selected,
    required this.onSelect,
  });
  final PaywallConfig cfg;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    // The yearly plan is the only purchasable one, so it always stays.
    final showMonthly = cfg.monthly.visible;
    return Positioned(
      top: 478,
      left: 24,
      width: 345,
      height: 186,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMonthly) ...[
            Expanded(
              child: _MonthlyCard(
                cfg.monthly,
                selected: selected == 'monthly',
                onTap: () => onSelect('monthly'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _YearlyCard(
              cfg.yearly,
              selected: selected == 'yearly',
              onTap: () => onSelect('yearly'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard(this.plan, {required this.selected, required this.onTap});
  final PaywallPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 182,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
            width: 2.94,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ),
                _SelectDot(selected: selected, size: 20),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.price,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 24,
                    height: 1,
                    letterSpacing: -0.3,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.period,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                height: 1,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            // Flexible: a long translation is cut at the card's edge, not overflowed.
            Flexible(
              child: Text(
                plan.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSubtitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio-style indicator: filled with a check when the plan is selected.
class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected, required this.size});
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : null,
        border: selected
            ? null
            : Border.all(color: const Color(0xFFE0E0E0), width: 2.2),
      ),
      alignment: Alignment.center,
      child: selected
          ? Icon(Icons.check, size: size * 0.6, color: Colors.white)
          : null,
    );
  }
}

class _YearlyCard extends StatelessWidget {
  const _YearlyCard(this.plan, {required this.selected, required this.onTap});
  final PaywallPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 182,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? null : const Color(0xFFE0E0E0),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFAA96FA), Color(0xFFABA6F9)],
                )
              : null,
        ),
        padding: const EdgeInsets.all(2.94),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(9.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        plan.badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  _SelectDot(selected: selected, size: 22),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                plan.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleDark,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.price,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 22,
                      height: 1,
                      letterSpacing: -0.3,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      plan.period,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        height: 1,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              if (plan.perMonthNote.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  plan.perMonthNote,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.5,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSubtitle,
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.originalPrice.isNotEmpty)
                    Text(
                      plan.originalPrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (plan.saveBadge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _kSaveGreenBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        plan.saveBadge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kSaveGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CONTINUE BUTTON
// -----------------------------------------------------------------------------

class _ContinueButton extends StatelessWidget {
  const _ContinueButton(this.cfg, {required this.selected, required this.pops});
  final PaywallConfig cfg;
  final String selected;
  final int pops;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 678,
      left: 24,
      width: 345,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFBCA4FC),
              offset: Offset(4, 4),
              blurRadius: 12.5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => selected == 'monthly'
                ? PaywallActions.buyMonthly(context, pops: pops)
                : PaywallActions.buyYearly(context, pops: pops),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFF8A56D1), Color(0xFF583DD0)],
                ),
              ),
              child: Center(
                child: PaywallBusy(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "Try 3 days free" only with a real trial on yearly;
                      // otherwise "Continue" (no sparkle).
                      Text(
                        cfg.s2CtaLabel,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COMMITMENT TEXT
// -----------------------------------------------------------------------------

class _CommitmentText extends StatelessWidget {
  const _CommitmentText(this.cfg, {required this.selected});
  final PaywallConfig cfg;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 742,
      left: 24,
      width: 345,
      child: Text(
        cfg.s2FinePrint(yearlySelected: selected == 'yearly'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          color: AppColors.textSubtitle,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FOOTER
// -----------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer(this.cfg, {required this.pops});
  final PaywallConfig cfg;
  final int pops;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 770,
      left: 16,
      width: 361,
      // Wraps instead of cutting a long translation; every link has a
      // comfortable touch area.
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FooterLink(
            text: cfg.restoreLabel,
            onTap: () => PaywallActions.restore(context, pops: pops),
          ),
          const _FooterDot(),
          _FooterLink(text: cfg.termsLabel, onTap: LegalLinks.openTermsOfUse),
          const _FooterDot(),
          _FooterLink(
            text: cfg.privacyLabel,
            onTap: LegalLinks.openPrivacyPolicy,
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5B5970),
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF9A98AC),
          ),
        ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '•',
        style: TextStyle(fontSize: 12, color: Color(0xFF9A98AC)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TABLET LAYOUT (shortest side >= 600)
// -----------------------------------------------------------------------------

class _TabletPaywall extends StatelessWidget {
  const _TabletPaywall({
    required this.cfg,
    required this.selected,
    required this.pops,
    required this.onSelect,
  });

  final PaywallConfig cfg;
  final String selected;
  final int pops;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _kBackgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              // 88% of the width, never wider than 640.
              final contentWidth = math.min(c.maxWidth * 0.88, 640.0);
              final landscape = c.maxWidth > c.maxHeight;
              final artHeight = landscape ? 150.0 : 230.0;
              return Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // The same artwork as the phone: cards, sparkles
                            // and the four icon badges, scaled to fit.
                            SizedBox(
                              height: artHeight,
                              width: contentWidth,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: const SizedBox(
                                  width: 393,
                                  height: 235,
                                  child: Stack(children: [_Artwork()]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              PaywallActions.headline ?? cfg.s2Title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 34,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.titleDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cfg.s2Subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 17,
                                color: AppColors.textTitle,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _TabletChips(cfg.s2Features),
                            const SizedBox(height: 24),
                            _TabletPlans(
                              cfg: cfg,
                              selected: selected,
                              onSelect: onSelect,
                            ),
                            const SizedBox(height: 20),
                            _TabletCta(
                              cfg: cfg,
                              selected: selected,
                              pops: pops,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              cfg.s2FinePrint(
                                yearlySelected: selected == 'yearly',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                color: AppColors.textSubtitle,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _FooterLink(
                                  text: cfg.restoreLabel,
                                  onTap: () => PaywallActions.restore(
                                    context,
                                    pops: pops,
                                  ),
                                ),
                                const _FooterDot(),
                                _FooterLink(
                                  text: cfg.termsLabel,
                                  onTap: LegalLinks.openTermsOfUse,
                                ),
                                const _FooterDot(),
                                _FooterLink(
                                  text: cfg.privacyLabel,
                                  onTap: LegalLinks.openPrivacyPolicy,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (cfg.showCloseButton || PaywallActions.skippable)
                    Positioned(
                      top: 12,
                      right: 20,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => PaywallActions.close(context, pops: pops),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9D7EC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 24,
                              color: Color(0xFF1F1F2E),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The highlights in a 2-column grid.
class _TabletChips extends StatelessWidget {
  const _TabletChips(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _TabletChip(items[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < items.length
                      ? _TabletChip(items[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TabletChip extends StatelessWidget {
  const _TabletChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly and Yearly side by side, the same height.
class _TabletPlans extends StatelessWidget {
  const _TabletPlans({
    required this.cfg,
    required this.selected,
    required this.onSelect,
  });

  final PaywallConfig cfg;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final showMonthly = cfg.monthly.visible;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showMonthly) ...[
            Expanded(
              child: _TabletPlanCard(
                plan: cfg.monthly,
                yearly: false,
                selected: selected == 'monthly',
                onTap: () => onSelect('monthly'),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: _TabletPlanCard(
              plan: cfg.yearly,
              yearly: true,
              selected: selected == 'yearly',
              onTap: () => onSelect('yearly'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletPlanCard extends StatelessWidget {
  const _TabletPlanCard({
    required this.plan,
    required this.yearly,
    required this.selected,
    required this.onTap,
  });

  final PaywallPlan plan;
  final bool yearly;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFAA96FA) : const Color(0xFFE0E0E0),
            width: 2.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Most Popular" sits above the title (the same row height on
            // both cards, so the titles and prices line up).
            SizedBox(
              height: 22,
              child: yearly && plan.badge.isNotEmpty
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          plan.badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            // The title, and the check mark at the far right of the card.
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SelectDot(selected: selected, size: 24),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      plan.price,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 32,
                        height: 1,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.w800,
                        color: yearly ? AppColors.primary : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  plan.period,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (yearly) ...[
              // One line: never wraps in the middle of the price.
              if (plan.perMonthNote.isNotEmpty)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    plan.perMonthNote,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSubtitle,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              // The struck price and the saving, side by side, with room.
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (plan.originalPrice.isNotEmpty)
                    Text(
                      plan.originalPrice,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (plan.saveBadge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kSaveGreenBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        plan.saveBadge,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kSaveGreen,
                        ),
                      ),
                    ),
                ],
              ),
            ] else
              Text(
                plan.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  height: 1.35,
                  color: AppColors.textSubtitle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The Continue button, as wide as the plan cards.
class _TabletCta extends StatelessWidget {
  const _TabletCta({
    required this.cfg,
    required this.selected,
    required this.pops,
  });

  final PaywallConfig cfg;
  final String selected;
  final int pops;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFBCA4FC),
              offset: Offset(4, 4),
              blurRadius: 12.5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => selected == 'monthly'
                ? PaywallActions.buyMonthly(context, pops: pops)
                : PaywallActions.buyYearly(context, pops: pops),
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFF8A56D1), Color(0xFF583DD0)],
                ),
              ),
              child: Center(
                child: PaywallBusy(
                  child: Text(
                    cfg.s2CtaLabel,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
