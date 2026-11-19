import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/utils/legal_links.dart';
import '../controller/subscription_controller.dart';
import '../models/paywall_config_model.dart';
import 'paywall_actions.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

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
  String _selected = 'monthly';

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
    final showClose = cfg.showCloseButton || PaywallActions.skippable;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _kBackgroundGradient),
        child: SafeArea(
          child: Center(
            // Phones use the full width, tablets get a centred column.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 28),
                        const _Artwork(),
                        const SizedBox(height: 14),
                        _Headline(PaywallActions.headline ?? cfg.s2Title),
                        const SizedBox(height: 18),
                        _FeatureList(cfg.s2Features),
                        const SizedBox(height: 22),
                        _PlanCardsRow(
                          cfg,
                          selected: selected,
                          onSelect: (plan) => setState(() => _selected = plan),
                        ),
                        const SizedBox(height: 22),
                        _ContinueButton(
                          cfg,
                          selected: selected,
                          pops: widget.pops,
                        ),
                        const SizedBox(height: 10),
                        _CommitmentText(cfg, selected: selected),
                        _Footer(cfg, pops: widget.pops),
                      ],
                    ),
                  ),
                  if (showClose)
                    Positioned(
                      top: 8,
                      right: 12,
                      child: _CloseButton(pops: widget.pops),
                    ),
                ],
              ),
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

const LinearGradient _kBackgroundGradient = LinearGradient(
  begin: Alignment(-0.193, -0.981),
  end: Alignment(0.193, 0.981),
  colors: [Color(0xFFDAD5FB), Color(0xFFF6F3FC), Color(0xFFE0E0FF)],
  stops: [0.0109, 0.5019, 0.993],
);

// -----------------------------------------------------------------------------
// CLOSE BUTTON — white circle, dark X (top right)
// -----------------------------------------------------------------------------

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.pops});
  final int pops;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 22,
            color: Color(0xFF1F1F2E),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ARTWORK — cards image + icon badges + sparkles, scaled to the screen width
// -----------------------------------------------------------------------------

class _Artwork extends StatelessWidget {
  const _Artwork();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 393 / 210,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 393,
          height: 210,
          child: Stack(
            children: [
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
              Positioned(
                top: 35,
                left: 120,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Color(0xFFAA96FA),
                ),
              ),
              Positioned(
                top: 20,
                left: 255,
                child: Icon(Icons.auto_awesome, size: 12, color: Colors.white),
              ),
              Positioned(
                top: 45,
                left: 290,
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color(0xFF7658E8),
                ),
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
              _IconBadge(top: 60, left: 70, icon: Icons.memory_rounded),
              _IconBadge(top: 78, left: 296, icon: Icons.gesture_rounded),
              _IconBadge(top: 128, left: 50, icon: Icons.grid_view_rounded),
              _IconBadge(top: 140, left: 300, icon: Icons.qr_code_2_rounded),
            ],
          ),
        ),
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
// HEADLINE — one bold line, shrinks instead of wrapping
// -----------------------------------------------------------------------------

class _Headline extends StatelessWidget {
  const _Headline(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: AppColors.titleDark,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FEATURE LIST — vertical, check circle + text (no pills, no subtitle)
// -----------------------------------------------------------------------------

class _FeatureList extends StatelessWidget {
  const _FeatureList(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PLAN CARDS — Monthly + Yearly side by side, same height
// -----------------------------------------------------------------------------

const Color _kSaveGreen = Color(0xFF2AA96B);
const Color _kSaveGreenBg = Color(0xFFE3F6EC);
const Color _kDivider = Color(0xFFEDEBF5);
const Color _kUnselectedBorder = Color(0xFFE0E0E0);

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
    final showMonthly = cfg.monthly.visible;
    return Padding(
      // room above for the "Most Popular" badge that overlaps the card edge
      padding: const EdgeInsets.only(top: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showMonthly) ...[
              Expanded(
                child: _MonthlyCard(
                  cfg.monthly,
                  selected: selected == 'monthly',
                  onTap: () => onSelect('monthly'),
                ),
              ),
              const SizedBox(width: 12),
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
      ),
    );
  }
}

BoxDecoration _cardDecoration(bool selected) => BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: selected ? AppColors.primary : _kUnselectedBorder,
    width: selected ? 1.6 : 1,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

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
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
        decoration: _cardDecoration(selected),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ),
                _SelectDot(selected: selected, size: 22),
              ],
            ),
            const SizedBox(height: 6),
            _PriceRow(plan: plan, color: Colors.black),
            const Spacer(),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: _kDivider),
            const SizedBox(height: 10),
            Text(
              plan.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                height: 1.3,
                color: AppColors.textSubtitle,
              ),
            ),
          ],
        ),
      ),
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
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 14, 14),
            decoration: _cardDecoration(selected),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.titleDark,
                        ),
                      ),
                    ),
                    _SelectDot(selected: selected, size: 22),
                  ],
                ),
                const SizedBox(height: 6),
                _PriceRow(plan: plan, color: AppColors.primary),
                const Spacer(),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: _kDivider),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (plan.originalPrice.isNotEmpty)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            plan.originalPrice,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    if (plan.saveBadge.isNotEmpty)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _kSaveGreenBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              plan.saveBadge,
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kSaveGreen,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // "Most Popular" straddles the top edge of the card, centred.
          if (plan.badge.isNotEmpty)
            Positioned(
              top: -13,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan.badge,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.plan, required this.color});
  final PaywallPlan plan;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            plan.price,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 28,
              height: 1.1,
              letterSpacing: -0.3,
              fontWeight: FontWeight.w800,
              color: color,
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
    );
  }
}

/// Radio-style indicator: filled with a check when selected, empty ring otherwise.
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
            : Border.all(color: const Color(0xFFD5D5DD), width: 1.5),
      ),
      alignment: Alignment.center,
      child: selected
          ? Icon(Icons.check, size: size * 0.64, color: Colors.white)
          : null,
    );
  }
}

// -----------------------------------------------------------------------------
// CONTINUE BUTTON — full width, purple gradient (dark left -> light right)
// -----------------------------------------------------------------------------

class _ContinueButton extends StatelessWidget {
  const _ContinueButton(this.cfg, {required this.selected, required this.pops});
  final PaywallConfig cfg;
  final String selected;
  final int pops;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF583DD0), Color(0xFF8A56F0)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55BCA4FC),
                offset: Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: InkWell(
            onTap: () => selected == 'monthly'
                ? PaywallActions.buyMonthly(context, pops: pops)
                : PaywallActions.buyYearly(context, pops: pops),
            child: Center(
              child: PaywallBusy(
                child: Text(
                  cfg.s2CtaFor(yearlySelected: selected == 'yearly'),
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
    );
  }
}

// -----------------------------------------------------------------------------
// COMMITMENT TEXT + FOOTER (kept small, below the button)
// -----------------------------------------------------------------------------

class _CommitmentText extends StatelessWidget {
  const _CommitmentText(this.cfg, {required this.selected});
  final PaywallConfig cfg;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return Text(
      cfg.s2FinePrint(yearlySelected: selected == 'yearly'),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 12,
        color: AppColors.textSubtitle,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer(this.cfg, {required this.pops});
  final PaywallConfig cfg;
  final int pops;

  @override
  Widget build(BuildContext context) {
    return Wrap(
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