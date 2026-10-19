import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/share_origin.dart';
import '../translations/tr_extension.dart';

/// This app's Play Store / App Store listing: opened for updates and ratings,
/// and shared by "Share App".
abstract final class StoreLinks {
  /// The listing page, or null when it can't be determined (iOS before the
  /// app is live in the App Store, or offline).
  ///
  /// Android: the https Play link (opens the Play Store app directly; a
  /// market:// link can show an app chooser when several stores exist).
  /// iOS: found by bundle id through the iTunes lookup, so no numeric Apple
  /// id has to be hard-coded.
  static Future<Uri?> listingUri() async {
    try {
      final id = (await PackageInfo.fromPlatform()).packageName;
      if (Platform.isAndroid) {
        return Uri.parse('https://play.google.com/store/apps/details?id=$id');
      }
      if (Platform.isIOS) {
        final res = await http
            .get(Uri.parse('https://itunes.apple.com/lookup?bundleId=$id'))
            .timeout(const Duration(seconds: 8));
        final results = (jsonDecode(res.body)['results'] as List?) ?? const [];
        final url = results.isEmpty ? null : results.first['trackViewUrl'];
        return url is String ? Uri.parse(url) : null;
      }
    } catch (e) {
      log('Could not resolve store listing: $e', name: 'StoreLinks');
    }
    return null;
  }

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
      if (Platform.isAndroid) {
        final id = (await PackageInfo.fromPlatform()).packageName;
        return launchUrl(
          Uri.parse('market://details?id=$id'),
          mode: LaunchMode.externalApplication,
        );
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
