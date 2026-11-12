import 'dart:developer';
import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

/// Terms and privacy pages, shared by the paywall footers and Settings
/// (the store requires working links next to a subscription offer). Same
/// pages as the other Clixade apps.
abstract final class LegalLinks {
  static const privacyPolicyIos = 'https://clixade.com/privacy-policy';
  static const privacyPolicyAndroid =
      'https://clixade.com/moessa-app/privacy-policy';
  static const supportEmailIos = 'contacts.clixade@gmail.com';
  static const supportEmailAndroid = 'amoessa777@gmail.com';
  static const termsOfUse = 'https://clixade.com/terms-and-conditions';
  static const contactUs = 'https://clixade.com/contact-us';

  /// This platform's privacy policy / support email.
  static String get privacyPolicy =>
      privacyPolicyFor(ios: Platform.isIOS);
  static String get supportEmail => supportEmailFor(ios: Platform.isIOS);

  static String privacyPolicyFor({required bool ios}) =>
      ios ? privacyPolicyIos : privacyPolicyAndroid;
  static String supportEmailFor({required bool ios}) =>
      ios ? supportEmailIos : supportEmailAndroid;

  static Future<void> openPrivacyPolicy() => _open(privacyPolicy);
  static Future<void> openTermsOfUse() => _open(termsOfUse);

  /// Contact Us: an email to this platform's support address.
  static Future<void> openContactUs() => _open('mailto:$supportEmail');

  static Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      log('could not open $url: $e', name: 'LegalLinks');
    }
  }
}
