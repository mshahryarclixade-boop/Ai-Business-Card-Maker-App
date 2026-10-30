import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/share_origin.dart';
import '../translations/tr_extension.dart';

/// This app's Play Store / App Store listing: opened for updates and ratings,
/// and shared by "Share App".
///
/// The listing addresses are NOT guessed: the app is not published yet, so a
/// link built from the package or bundle id would lead nowhere. Set them when
/// the listings exist, at build time:
///
///   flutter run --dart-define=PLAY_STORE_URL=https://play.google.com/store/apps/details?id=...
///               --dart-define=APP_STORE_URL=https://apps.apple.com/app/id...
///
/// Without them, Rate App says the store page is not available yet and Share
/// App shares the plain invitation text.
abstract final class StoreLinks {
  static const String playStoreUrl = String.fromEnvironment('PLAY_STORE_URL');
  static const String appStoreUrl = String.fromEnvironment('APP_STORE_URL');

  /// The configured listing for this platform, or null when there is none
  /// (not configured yet, an unsupported platform or an invalid address).
  static Uri? get listing => parse(
    Platform.isAndroid
        ? playStoreUrl
        : Platform.isIOS
        ? appStoreUrl
        : '',
  );

  /// [raw] as an http(s) address, or null when it is empty or not one.
  static Uri? parse(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final u = Uri.tryParse(t);
    return u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty
        ? u
        : null;
  }

  static Future<Uri?> listingUri() async => listing;

  /// Opens the listing; with [review] it opens the App Store's "write a
  /// review" page on iOS (Android's listing has the rating box on top).
  /// Returns false when nothing could be opened.
  static Future<bool> open({bool review = false}) async {
    var uri = await listingUri();
    if (uri == null) return false;
    if (review && Platform.isIOS) {
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, 'action': 'write-review'},
      );
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      log('Could not open store: $e', name: 'StoreLinks');
    }
    return false;
  }

  /// Opens the store for a rating, with a message when it isn't available.
  static Future<void> rateApp() async {
    if (!await open(review: true)) _notAvailable();
  }

  /// Opens the system share sheet with the app's store link.
  static Future<void> shareApp([BuildContext? context]) async {
    // Measured before any await, while the context is still valid.
    final origin = shareOrigin(context);
    try {
      final link = await listingUri();
      final text = link == null
          ? 'store_share_text'.tr
          : 'store_share_text_with_link'.trParams({'link': link});
      await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
    } catch (e) {
      log('Could not share app: $e', name: 'StoreLinks');
      Get.snackbar(
        'store_share_failed_title'.tr,
        'store_share_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  static void _notAvailable() => Get.snackbar(
    'store_not_available_title'.tr,
    'store_not_available_message'.tr,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(15),
  );
}
