import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Splash screen
  static const Color splashBg = Color(0xFFFDFDFD);
  static const Color splashTextPrimary = Color(0xFF1C1C1C);
  static const Color splashTextSecondary = Color(0xFF737373);
  static const Color splashProgress = Color(0xFF5425CF);

  // Onboarding
  static const Color onboardingTopCardBg = Color(0xFFF4F4FF);
  static const Color onboardingIconBg = Color(0xFFE8E8FB);
  static const Color onboardingBtnStart = Color(0xFF524DBE);
  static const Color onboardingBtnEnd = Color(0xFF3F3CA3);
  static const Color onboardingBtnShadow = Color(0x12000000);
  static const Color onboardingCardShadow = Color(0x14000000);
  // Purple used for "Endless Possibilities."
  static const Color onboardingAccent = onboardingBtnStart;

  static const LinearGradient onboardingButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [onboardingBtnStart, onboardingBtnEnd],
  );

  // Profile setup
  static const Color profileStepActive = Color(0xFF4D48B7);
  static const Color profileStepInactive = Color(0xFFF0F0F0);
  static const Color profileStepLabel = Color(0xFF282828);
  static const Color profileFieldBorder = Color(0xFFCCCDCF);
  static const Color profileHintBg = Color(0xFFF5F5F5);
  static const Color profileHintBorder = Color(0xFFEAEDF1);
  static const Color profileHintText = Color(0xFF878787);
  static const Color profileError = Color(0xFFD93025);
  static const Color profileOptionSelectedBg = Color(0xFFF5F5FF);
  static const Color profileLink = Color(0xFF0789DA);

  // First card generation
  static const Color firstCardCheck = Color(0xFF4440AA);

  // CSS: linear-gradient(180deg, #FFFFFF 68.6%, #EDEDFF 100%)
  static const LinearGradient firstCardBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFEDEDFF)],
    stops: [0.0, 0.686, 1.0],
  );

  // Brand
  static const Color primary = Color(0xFF5858B5); // circle / progress fill
  static const Color primaryDark = Color(0xFF2E2B65);
  // headline text
  static const Color bottomselcted = Color(0xFF444494); // headline text


  // Text
  static const Color textTitle = primaryDark;
  static const Color textSubtitle = Color(0xFF68686A);
  static const Color textBody = Color(0xFF4A4A55);

  static const Color background = Color(0xFFF5F5F5);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color progressTrack = Color(0xFFEDEDF6);

  // OLD Splash / Onboarding background gradient
  static const Color splashGradientStart = Color(0xFFFFFFFF);
  static const Color splashGradientEnd = Color(0xFFE0E0FF);

  static const LinearGradient splashBackground = LinearGradient(
    begin: Alignment(-0.21, -0.98),
    end: Alignment(0.21, 0.98),
    colors: [splashGradientStart, splashGradientEnd],
    stops: [0.0, 0.9929],
  );

  static const Color buttonDark = Color(0xFF474796); // Next button bg
  static const Color titleDark = Color(0xFF1E1E24); // onboarding title
  static const Color dotInactive = Color(0xFFD8D6E8); // inactive dot

  static const Color pillBg = Color(0xFFFFFFFF);
  static const Color pillBorder = Color(0xFFE4E2FF);
  static const Color pillIconBg = Color(0xFFDFDFDF);
  static const Color pillLabelGrey = Color(0xFF888888);

  // Home screen
  static const Color scaffoldBg = Color(0xFFF7F7FB);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color iconTileBg = Color(0xFFFFFFFF);
  static const Color iconTileBorder = Color(0xFFEFEDF7);

  static const Color generateCardStart = Color(0xFF444494);
  static const Color generateCardEnd = Color(0xFF9B5BFF);

  static const LinearGradient generateCardGradient = LinearGradient(
    begin: Alignment(-1, -0.3),
    end: Alignment(1, 0.3),
    colors: [generateCardStart, generateCardEnd],
  );

  static const Color topBarGradientStart = Color(0xFF444494);
  static const Color topBarGradientEnd = Color(0xFF6060BF);

  static const LinearGradient topBarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      topBarGradientStart,
      topBarGradientEnd,
    ],
    stops: [
      0.1939,
      0.8533,
    ],
  );

  static const Color customCreateBg = Color(0xFFF3F3FA);

  static Color customCreateBorder =
  const Color(0xFF444494).withOpacity(0.4);

  static const Color bottomNavBg = Color(0xFFFFFFFF);
  static const Color bottomNavActiveBg = Color(0xFFEDEBFB);
  static const Color bottomNavInactive = Color(0xFF333232);

  // ---------------------------------------------------------------------------
  // Contacts screen
  // ---------------------------------------------------------------------------

  static const Color contactsLavenderBg = Color(0xFFEDEAFB);
  static const Color contactsLavenderBorder = Color(0xFFD6CFF6);

  static const Color contactsScaffoldBg = Color(0xFFF5F5F7);
  static const Color contactsTitleDark = Color(0xFF1E1E2A);
  static const Color contactsSubtitleGrey = Color(0xFF8A8A97);
  static const Color contactsSearchBg = Color(0xFFF0F0F3);

  static const Color contactsPremiumIcon = Color(0xFFF5A623);

  // Contact detail photo fallback gradient
  static const Color contactsPhotoGradientStart = Color(0xFF66C7F4);
  static const Color contactsPhotoGradientEnd = Color(0xFF4FB3E8);

  // Contact detail overlay
  static const Color black26 = Colors.black26;

  static const Color primarySoft = Color(0xFFEFEDFF); // inactive pill bg

  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF8A8A9E);

  static const Color favorite = Color(0xFF4E3FF2);
  static const Color crownGold = Color(0xFFFFC94A);

  static const Color cardShadow = Color(0x1A000000);
}