import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'paywall_view_2.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const double _kDesignWidth = 393;
const double _kDesignHeight = 860;

class PaywallView extends StatelessWidget {
  const PaywallView({super.key});

  @override
  Widget build(BuildContext context) {
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
                        _CloseButton(),
                        const _Headline(),
                        const _Subtitle(),
                        const _FeatureCard(),
                        const _YearlyProCard(),
                        const _TrialButton(),
                        const _TrialInfoTexts(),
                        const _Footer(),
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
        onTap: () => Get.back(),
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
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 180,
      left: (393 - 215) / 2,
      width: 215,
      height: 60,
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 26,
            height: 1.0,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(
              text: 'Start creating\n',
              style: TextStyle(color: AppColors.titleDark),
            ),
            TextSpan(
              text: 'for free',
              style: TextStyle(color: AppColors.primary),
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
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 244,
      left: 46.5,
      width: 300,
      child: Text(
        'Unlock everything with Pro',
        textAlign: TextAlign.center,
        style: TextStyle(
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
  const _FeatureCard();

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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FeatureRow(
              icon: Icons.auto_awesome,
              text: 'Unlimited AI Card Generation',
            ),
            _FeatureRow(
              icon: Icons.document_scanner_outlined,
              text: 'Scan Unlimited Cards',
            ),
            _FeatureRow(
              icon: Icons.layers_outlined,
              text: '50+ Premium Templates',
            ),
            _FeatureRow(
              icon: Icons.qr_code_scanner_rounded,
              text: 'Scan any QR Code',
            ),
            _FeatureRow(
              icon: Icons.auto_fix_high_rounded,
              text: 'Remove Background',
            ),
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
  const _YearlyProCard();

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
                  const Text(
                    'Yearly Pro',
                    style: TextStyle(
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
                    child: const Text(
                      'Save 70%',
                      style: TextStyle(
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
                  const Text(
                    '\$29.99',
                    style: TextStyle(
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
                      '/year',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                'Just \$2.49/month, billed annually',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.textSubtitle,
                ),
              ),
              const Divider(height: 1, color: Color(0xFFDCD9E9)),
              Row(
                children: const [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '3 days completely free, no charge today',
                      style: TextStyle(
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
  const _TrialButton();

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
              Get.to(
                () => const PaywallView2(),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Start 3-Day Free Trial',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
  const _TrialInfoTexts();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 738,
      left: 24,
      width: 345,
      child: Column(
        children: [
          Text(
            'No payment today, \$29.99/year after trial',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              color: AppColors.textSubtitle,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Cancel anytime before trial ends',
            textAlign: TextAlign.center,
            style: TextStyle(
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
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 790,
      left: 24,
      width: 345,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FooterLink(text: 'Restore Purchase'),
          _FooterDot(),
          _FooterLink(text: 'Term Of Use'),
          _FooterDot(),
          _FooterLink(text: 'Privacy Policy'),
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
