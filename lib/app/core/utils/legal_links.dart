import 'dart:developer';

import 'package:url_launcher/url_launcher.dart';

/// Terms and privacy pages, shared by the paywall footers and Settings
/// (the store requires working links next to a subscription offer). Same
/// pages as the other Clixade apps.
abstract final class LegalLinks {
  static const privacyPolicy = 'https://clixade.com/privacy-policy';
  static const termsOfUse = 'https://clixade.com/terms-and-conditions';
  static const contactUs = 'https://clixade.com/contact-us';

  static Future<void> openPrivacyPolicy() => _open(privacyPolicy);
  static Future<void> openTermsOfUse() => _open(termsOfUse);
  static Future<void> openContactUs() => _open(contactUs);

  static Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      log('could not open $url: $e', name: 'LegalLinks');
    }
  }
}
