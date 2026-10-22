import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../model/email_signature.dart';

/// Sizes shared by all three styles, so only colours and layout differ.
const _avatarSize = 54.0;
const _logoSize = 30.0;
const _qrSize = 46.0;
const _nameSize = 15.5;
const _roleSize = 12.5;
const _contactSize = 12.0;

/// A signature drawn in its chosen style. Email content is always laid out
/// left-to-right like a real email client would, except for the text itself.
class SignatureCard extends StatelessWidget {
  const SignatureCard({super.key, required this.sig, this.background = true});

  final EmailSignature sig;

  /// Draw the style's banner behind the signature. [SignatureFrame] turns
  /// this off because it paints the background on the whole card instead.
  final bool background;

  @override
  Widget build(BuildContext context) =>
      _Layout(sig, _Look.of(sig.style), background: background);
}

/// The final screen's card: the signature on its style's background (white
/// for Classic, a soft grey for Compact, a bold gradient for Banner), with
/// the "Made with" line when [madeWith] is given.
class SignatureFrame extends StatelessWidget {
  const SignatureFrame({super.key, required this.sig, this.madeWith});

  final EmailSignature sig;
  final String? madeWith;

  @override
  Widget build(BuildContext context) {
    final look = _Look.of(sig.style);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: look.frameColor,
        gradient: look.background,
        borderRadius: BorderRadius.circular(28),
        border: look.background == null
            ? Border.all(color: AppColors.pillBorder, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: SignatureCard(sig: sig, background: false),
          ),
          if (madeWith != null) ...[
            const SizedBox(height: 10),
            Text(madeWith!, style: _t(11, look.madeWith)),
          ],
        ],
      ),
    );
  }
}

TextStyle _t(double size, Color color, {FontWeight? weight, double? height}) =>
    TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: size,
      height: height,
      fontWeight: weight,
      color: color,
    );

/// Colours and small layout differences of each style.
class _Look {
  const _Look({
    required this.name,
    required this.role,
    required this.contact,
    required this.bar,
    required this.logoBg,
    required this.logoFg,
    this.background,
    this.frameColor = Colors.white,
    this.madeWith = AppColors.textSubtitle,
    this.divider = false,
    this.onDark = false,
    this.subtle = false,
  });

  final Color name;
  final Color role;
  final Color contact;

  /// The vertical accent bar (null = none).
  final Color? bar;
  final Color logoBg;
  final Color logoFg;

  /// A filled banner behind the whole signature.
  final Gradient? background;

  /// Background of the final screen's card when there's no gradient.
  final Color frameColor;

  /// Colour of the "Made with" line under the signature.
  final Color madeWith;

  /// A hairline between the role and the contact line.
  final bool divider;
  final bool onDark;
  final bool subtle;

  /// The default: blue accents on white.
  static const classic = _Look(
    name: AppColors.titleDark,
    role: AppColors.onboardingBtnEnd,
    contact: AppColors.textSubtitle,
    bar: AppColors.onboardingBtnEnd,
    logoBg: AppColors.onboardingBtnEnd,
    logoFg: Colors.white,
  );

  /// Classic with the colour taken out: greys only, a hairline instead of
  /// the blue bar.
  static const compact = _Look(
    name: AppColors.titleDark,
    role: AppColors.textBody,
    contact: AppColors.textGrey,
    bar: null,
    logoBg: Color(0xFFDDE1EA),
    logoFg: AppColors.titleDark,
    frameColor: Color(0xFFF1F3F8),
    divider: true,
    subtle: true,
  );

  /// Bold: a deep-blue gradient banner with a gold role line.
  static const banner = _Look(
    name: Colors.white,
    role: AppColors.crownGold,
    contact: Color(0xE6FFFFFF),
    bar: null,
    logoBg: Colors.white,
    logoFg: AppColors.onboardingBtnEnd,
    background: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [Color(0xFF3352DB), Color(0xFF111B4F)],
    ),
    madeWith: Color(0xCCFFFFFF),
    onDark: true,
  );

  static _Look of(SignatureStyle s) => switch (s) {
    SignatureStyle.classic => classic,
    SignatureStyle.compact => compact,
    SignatureStyle.banner => banner,
  };
}

class _Layout extends StatelessWidget {
  const _Layout(this.sig, this.look, {this.background = true});

  final EmailSignature sig;
  final _Look look;
  final bool background;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sig.fullName,
          style: _t(_nameSize, look.name, weight: FontWeight.w800),
        ),
        if (sig.roleLine.isNotEmpty)
          Text(
            sig.roleLine,
            style: _t(
              _roleSize,
              look.role,
              weight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        if (look.divider && sig.contactLine.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            height: 1,
            color: AppColors.pillBorder,
          ),
        if (sig.contactLine.isNotEmpty)
          Text(
            sig.contactLine,
            style: _t(_contactSize, look.contact, height: 1.35),
          ),
      ],
    );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SignatureAvatar(bytes: sig.photo, size: _avatarSize, ring: look.onDark),
        const SizedBox(width: 12),
        if (look.bar != null)
          Container(width: 2.5, height: _avatarSize + 6, color: look.bar),
        if (look.bar != null) const SizedBox(width: 10),
        Expanded(child: text),
        const SizedBox(width: 8),
        SignatureLogo(
          bytes: sig.logo,
          company: sig.company,
          size: _logoSize,
          background: look.logoBg,
          foreground: look.logoFg,
        ),
        if (sig.showQr) ...[
          const SizedBox(width: 8),
          SignatureQr(data: sig.qrData, size: _qrSize, onDark: look.onDark),
        ],
      ],
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        if (sig.showBookCall) ...[
          const SizedBox(height: 8),
          BookCallPill(onDark: look.onDark, subtle: look.subtle),
        ],
      ],
    );

    if (look.background == null || !background) return content;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: look.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: content,
    );
  }
}

/// Round photo. Until the user picks one, a simple illustrated avatar.
class SignatureAvatar extends StatelessWidget {
  const SignatureAvatar({
    super.key,
    required this.bytes,
    required this.size,
    this.ring = false,
  });

  final Uint8List? bytes;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE8EEFF),
        border: ring ? Border.all(color: Colors.white, width: 2) : null,
        image: bytes == null
            ? null
            : DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover),
      ),
      child: bytes == null ? CustomPaint(painter: _AvatarPainter()) : null,
    );
  }
}

class _AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Shoulders.
    canvas.drawOval(
      Rect.fromLTWH(w * 0.12, h * 0.68, w * 0.76, h * 0.62),
      Paint()..color = const Color(0xFF233062),
    );
    // Head.
    final head = Rect.fromCircle(
      center: Offset(w * 0.5, h * 0.42),
      radius: w * 0.19,
    );
    canvas.drawOval(head, Paint()..color = const Color(0xFFE3C3A0));
    // Hair.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h * 0.36));
    canvas.drawOval(
      head.inflate(w * 0.015),
      Paint()..color = const Color(0xFF2A1F1A),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Company logo; the company's first letter in a rounded badge until set.
class SignatureLogo extends StatelessWidget {
  const SignatureLogo({
    super.key,
    required this.bytes,
    required this.company,
    required this.size,
    this.background = AppColors.onboardingBtnEnd,
    this.foreground = Colors.white,
  });

  final Uint8List? bytes;
  final String company;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final letter = company.trim().isEmpty
        ? ''
        : company.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.34),
        color: background,
        image: bytes == null
            ? null
            : DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover),
      ),
      child: bytes == null
          ? Text(
              letter,
              style: _t(size * 0.5, foreground, weight: FontWeight.w800),
            )
          : null,
    );
  }
}

class SignatureQr extends StatelessWidget {
  const SignatureQr({
    super.key,
    required this.data,
    required this.size,
    this.onDark = false,
  });

  final String data;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: onDark ? null : Border.all(color: AppColors.pillBorder),
      ),
      child: QrImageView(
        data: data,
        padding: EdgeInsets.zero,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}

class BookCallPill extends StatelessWidget {
  const BookCallPill({super.key, this.onDark = false, this.subtle = false});

  /// On the dark banner: a white pill.
  final bool onDark;

  /// Compact style: an outlined grey pill.
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final Color bg = onDark
        ? Colors.white
        : subtle
        ? Colors.white
        : AppColors.onboardingBtnEnd;
    final Color fg = onDark || subtle ? AppColors.titleDark : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: subtle ? Border.all(color: AppColors.pillBorder) : null,
      ),
      child: Text(
        'email_sig_book_button'.tr,
        style: _t(_contactSize - 0.5, fg, weight: FontWeight.w700),
      ),
    );
  }
}
