import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/utils/legal_links.dart';
import '../controller/subscription_controller.dart';
import '../models/paywall_config_model.dart';
import 'paywall_actions.dart';
import 'paywall_view_2.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const double _kDesignWidth = 393;
const double _kDesignHeight = 860;

class PaywallView extends StatelessWidget {
  const PaywallView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    // Rebuilt once the store products (real prices) load.
    Get.find<SubscriptionController>().products.length;
    return _build(context);
  });

  Widget _build(BuildContext context) {
    final cfg = RemoteConfigService().paywallConfig;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _kBackgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / _kDesignWidth;
              return OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: _kDesignWidth,
                maxWidth: _kDesignWidth,
                minHeight: _kDesignHeight,
                maxHeight: _kDesignHeight,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: _kDesignWidth,
                    height: _kDesignHeight,
                    child: Stack(
                      children: [
                        const _ArtworkCards(),
                        if (cfg.showCloseButton) _CloseButton(),
                        _Headline(cfg),
                        _Subtitle(cfg),
                        _FeatureCard(cfg),
                        _YearlyProCard(cfg),
                        _TrialButton(cfg),
                        if (cfg.trialEnabled) _TrialInfoTexts(cfg),
                        _Footer(cfg),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BACKGROUND
// -----------------------------------------------------------------------------

// background: linear-gradient(168.07deg, #FFFFFF 0%, #E0E0FF 99.29%);
const LinearGradient _kBackgroundGradient = LinearGradient(
  begin: Alignment(-0.207, -0.978),
  end: Alignment(0.207, 0.978),
  colors: [Color(0xFFFFFFFF), Color(0xFFE0E0FF)],
  stops: [0.0, 0.9929],
);

// -----------------------------------------------------------------------------
// CLOSE BUTTON
// -----------------------------------------------------------------------------

class _CloseButton extends StatelessWidget {
  _CloseButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 24,
      child: GestureDetector(
        onTap: () => PaywallActions.exit(),
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFE5E4F1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 16,
            color: Color(0xFF292938),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ARTWORK — card2.png behind (tilted), card1.png in front on top of it.
// -----------------------------------------------------------------------------

class _ArtworkCards extends StatelessWidget {
  const _ArtworkCards();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Decorative sparkles (unchanged).
        const Positioned(
          top: 20,
          left: 110,
          child: Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6956FF)),
        ),
        const Positioned(
          top: 60,
          left: 35,
          child: Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD1C7FF)),
        ),
        const Positioned(
          top: 132,
          left: 308,
          child: Icon(Icons.auto_awesome, size: 16, color: Color(0xFF715EFF)),
        ),

        // card2 — behind. Same center as before, box is taller (124 -> 156).
        const _ArtworkImageCard(
          assetPath: 'assets/images/card2.png',
          top: 12.9,
          left: 117.79,
          width: 184,
          height: 156,
        ),

        // card1 — front. Same center as before, box is taller (118 -> 150).
        const _ArtworkImageCard(
          assetPath: 'assets/images/card1.png',
          top: 22,
          left: 52,
          width: 177,
          height: 150,
        ),
      ],
    );
  }
}

class _ArtworkImageCard extends StatelessWidget {
  final String assetPath;
  final double top;
  final double left;
  final double width;
  final double height;

  const _ArtworkImageCard({
    required this.assetPath,
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // contain = the whole image is always visible, never cropped.
    final image = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft shadow that follows the PNG's own shape (a box shadow on a
          // taller box would show up as a rectangle behind the tilted card).
          Transform.translate(
            offset: const Offset(3, 4),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.15),
                  BlendMode.srcIn,
                ),
                child: image,
              ),
            ),
          ),
          image,
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HEADLINE — "Start creating" / "for free"
// -----------------------------------------------------------------------------

class _Headline extends StatelessWidget {
  const _Headline(this.cfg);
  final PaywallConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 180,
      left: (393 - 215) / 2,
      width: 215,
      height: 60,
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 26,
            height: 1.0,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(
              text: '${cfg.s1TitleLine1}\n',
              style: const TextStyle(color: AppColors.titleDark),
            ),
            TextSpan(
              text: cfg.s1TitleLine2,
              style: const TextStyle(color: AppColors.primary),
            ),
          ],
        ),
        textAlign: TextAlign.center,
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
      top: 244,
      left: 46.5,
      width: 300,
      child: Text(
        cfg.s1Subtitle,
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
// FEATURE CARD — top:270, left:24, width:345, height:196, radius:12
// -----------------------------------------------------------------------------

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(this.cfg);
  final PaywallConfig cfg;

  static IconData _icon(String key) => switch (key) {
    'ai' => Icons.auto_awesome,
    'scan' => Icons.document_scanner_outlined,
    'templates' => Icons.layers_outlined,
    'qr' => Icons.qr_code_scanner_rounded,
    'bg' => Icons.auto_fix_high_rounded,
    _ => Icons.check_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 275,
      left: 24,
      width: 345,
      height: 190,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final f in cfg.s1Features)
              _FeatureRow(icon: _icon(f.icon), text: f.text),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFFE8E5FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textBody,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// YEARLY PRO CARD (selected) — top:480, left:24, width:345, height:184
// border: 4px solid gradient(180deg, #AA96FA -> #ABA6F9), radius:12
// box-shadow: 3px 4px 4px 0px #C9C8FE
// -----------------------------------------------------------------------------

class _YearlyProCard extends StatelessWidget {
  const _YearlyProCard(this.cfg);
  final PaywallConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 475,
      left: 24,
      width: 345,
      height: 184,
      child: Container(
        // Outer container paints the gradient "border".
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFAA96FA), Color(0xFFABA6F9)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFC9C8FE),
              offset: Offset(3, 4),
              blurRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cfg.s1PlanTitle,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7658E8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cfg.s1SaveBadge,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    cfg.yearly.price,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      cfg.yearly.period,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                cfg.s1PriceNote,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.textSubtitle,
                ),
              ),
              if (cfg.trialEnabled) ...[
                const Divider(height: 1, color: Color(0xFFDCD9E9)),
                Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cfg.trialBenefitText,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          height: 1.2,
                          color: AppColors.textSubtitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TRIAL BUTTON — top:680, left:24, width:345, height:56, radius:8
// background: linear-gradient(271.05deg, #8A56D1 -> #583DD0) + black 20% overlay
// box-shadow: 4px 4px 12.5px 0px #BCA4FC
// -----------------------------------------------------------------------------

class _TrialButton extends StatelessWidget {
  const _TrialButton(this.cfg);
  final PaywallConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 670,
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
            onTap: () {
              if (!cfg.showPlansScreen) {
                PaywallActions.buyYearly(context);
                return;
              }
              Get.to(
                () => const PaywallView2(),
                arguments: Get.arguments,
                transition: Transition.rightToLeft,
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 271.05deg gradient ~ right -> left flow.
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [Color(0xFF8A56D1), Color(0xFF583DD0)],
                    ),
                  ),
                ),
                // linear-gradient(0deg, rgba(0,0,0,.2), rgba(0,0,0,.2)) -> flat overlay.
                Container(color: Colors.black.withOpacity(0.2)),
                Center(
                  child: PaywallBusy(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cfg.trialButtonLabel,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TRIAL INFO TEXTS
// -----------------------------------------------------------------------------

class _TrialInfoTexts extends StatelessWidget {
  const _TrialInfoTexts(this.cfg);
  final PaywallConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 738,
      left: 24,
      width: 345,
      child: Column(
        children: [
          Text(
            cfg.trialInfoLine1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              color: AppColors.textSubtitle,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            cfg.trialInfoLine2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              color: AppColors.textSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FOOTER
// -----------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer(this.cfg);
  final PaywallConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 790,
      left: 24,
      width: 345,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => PaywallActions.restore(context),
            child: _FooterLink(text: cfg.restoreLabel),
          ),
          const _FooterDot(),
          GestureDetector(
            onTap: LegalLinks.openTermsOfUse,
            child: _FooterLink(text: cfg.termsLabel),
          ),
          const _FooterDot(),
          GestureDetector(
            onTap: LegalLinks.openPrivacyPolicy,
            child: _FooterLink(text: cfg.privacyLabel),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;

  const _FooterLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 9,
        color: Color(0xFF8A8896),
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
      child: Text('•', style: TextStyle(fontSize: 9, color: Color(0xFFAAA8B4))),
    );
  }
}
