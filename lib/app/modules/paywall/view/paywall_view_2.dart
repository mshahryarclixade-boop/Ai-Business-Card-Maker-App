import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

const double _kDesignWidth = 393;
const double _kDesignHeight = 860;

class PaywallView2 extends StatelessWidget {
  const PaywallView2({super.key});

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
                    child: const Stack(
                      children: [
                        _Artwork(),
                        _CloseButton(),
                        _Headline(),
                        _Subtitle(),
                        _FeaturePills(),
                        _PlanCardsRow(),
                        _ContinueButton(),
                        _CommitmentText(),
                        _Footer(),
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
  const _CloseButton();

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
// HEADLINE — "Unlock Pro & keep creating"
// -----------------------------------------------------------------------------

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 225,
      left: (393 - 320) / 2,
      width: 320,
      child: Text(
        'Unlock Pro & keep creating',
        textAlign: TextAlign.center,
        style: TextStyle(
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
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 290,
      left: 46.5,
      width: 300,
      child: Text(
        'Get unlimited access to every feature',
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
// FEATURE PILLS — 3 rows x 2 columns
// -----------------------------------------------------------------------------

class _FeaturePills extends StatelessWidget {
  const _FeaturePills();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 330,
      left: 24,
      width: 345,
      child: Column(
        children: [
          _PillRow(left: 'Unlimited AI Card', right: 'Unlimited Scan'),
          SizedBox(height: 10),
          _PillRow(left: '50+ Templates', right: 'No watermark'),
          SizedBox(height: 10),
          _PillRow(left: 'QR Generator', right: 'BG Remover'),
        ],
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  final String left;
  final String right;

  const _PillRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PillBadge(text: left),
        const SizedBox(width: 10),
        _PillBadge(text: right),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String text;

  const _PillBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              overflow: TextOverflow.ellipsis,
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
    );
  }
}

// -----------------------------------------------------------------------------
// PLAN CARDS — Monthly (unselected) + Yearly (selected, "Most Popular")
// -----------------------------------------------------------------------------

const Color _kSaveGreen = Color(0xFF2AA96B);
const Color _kSaveGreenBg = Color(0xFFE3F6EC);

class _PlanCardsRow extends StatelessWidget {
  const _PlanCardsRow();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 490,
      left: 24,
      width: 345,
      height: 165,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _MonthlyCard()),
          SizedBox(width: 10),
          Expanded(child: _YearlyCard()),
        ],
      ),
    );
  }
}

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 2.94,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleDark,
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 2.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '\$6.99',
                style: TextStyle(
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
            '/month',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              height: 1,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Full access to all Pro features',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w400,
              color: AppColors.textSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearlyCard extends StatelessWidget {
  const _YearlyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFAA96FA), Color(0xFFABA6F9)],
        ),
      ),
      padding: const EdgeInsets.all(2.94),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Most Popular',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, size: 13, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Yearly',
              style: TextStyle(
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
                const Text(
                  '\$29.99',
                  style: TextStyle(
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
                    '/year',
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
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$83.88/year',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kSaveGreenBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Save 70%',
                    style: TextStyle(
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
    );
  }
}

// -----------------------------------------------------------------------------
// CONTINUE BUTTON
// -----------------------------------------------------------------------------

class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 680,
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
            onTap: () {},
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFF8A56D1), Color(0xFF583DD0)],
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Continue',
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
  const _CommitmentText();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 750,
      left: 24,
      width: 345,
      child: Text(
        'No commitment, cancel anytime',
        textAlign: TextAlign.center,
        style: TextStyle(
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
