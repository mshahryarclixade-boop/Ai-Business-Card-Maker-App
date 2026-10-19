import 'en/ai_card_strings.dart';
import 'en/career_studio_strings.dart';
import 'en/contacts_strings.dart';
import 'en/core_strings.dart';
import 'en/custom_create_strings.dart';
import 'en/home_strings.dart';
import 'en/main_nav_strings.dart';
import 'en/onboarding_strings.dart';
import 'en/paywall_strings.dart';
import 'en/profile_setup_strings.dart';
import 'en/profile_strings.dart';
import 'en/qr_code_strings.dart';
import 'en/recent_designs_strings.dart';
import 'en/remove_background_strings.dart';
import 'en/scan_strings.dart';
import 'en/services_strings.dart';
import 'en/settings_strings.dart';
import 'en/splash_strings.dart';
import 'en/template_strings.dart';
import 'en/widgets_strings.dart';

/// All English strings, merged from the per-feature files in `en/`.
/// Keys must be unique across files (checked by test/localization_test.dart).
const Map<String, String> enStrings = {
    ...coreStrings,
    ...aiCardStrings,
    ...careerStudioStrings,
    ...contactsStrings,
    ...customCreateStrings,
    ...homeStrings,
    ...mainNavStrings,
    ...onboardingStrings,
    ...paywallStrings,
    ...profileStrings,
    ...profileSetupStrings,
    ...qrCodeStrings,
    ...recentDesignsStrings,
    ...removeBackgroundStrings,
    ...scanStrings,
    ...settingsStrings,
    ...splashStrings,
    ...templateStrings,
    ...widgetsStrings,
    ...servicesStrings,
};
