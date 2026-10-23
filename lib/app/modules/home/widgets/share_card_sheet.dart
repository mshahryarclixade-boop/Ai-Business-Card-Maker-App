import 'dart:convert';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart' hide Trans;
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_origin.dart';
import '../../qr_code_generator/model/qr_style.dart';
import '../../qr_code_generator/service/qr_store.dart';
import '../../qr_code_generator/view/qr_preview_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile_setup/model/user_profile_data.dart';
import '../../profile_setup/service/profile_store.dart';
import '../../qr_code_generator/view/qr_code_screen.dart';
import '../../../core/translations/tr_extension.dart';

const String kCardPageUrl = 'https://ai-business-card-e1cde.web.app/card.html';

void _snack(String title, String message) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(15),
  );
}

/// The four options shown when the user taps Share Card.
void showShareCardSheet(File cardImage) {
  Get.bottomSheet(
    _ShareCardSheet(cardImage: cardImage),
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  );
}

class _ShareCardSheet extends StatelessWidget {
  const _ShareCardSheet({required this.cardImage});

  final File cardImage;

  /// Builds the link: card details are packed into the part after '#',
  /// which the web page reads. Empty fields are left out.
  String _buildCardLink(UserProfileData d) {
    final map = <String, String>{
      if (d.fullName.trim().isNotEmpty) 'n': d.fullName.trim(),
      if (d.companyName.trim().isNotEmpty) 'c': d.companyName.trim(),
      if (d.designation.trim().isNotEmpty) 'd': d.designation.trim(),
      if (d.phone.trim().isNotEmpty) 'p': d.phone.trim(),
      if (d.email.trim().isNotEmpty) 'e': d.email.trim(),
      if (d.website.trim().isNotEmpty) 'w': d.website.trim(),
    };
    final encoded = base64Url
        .encode(utf8.encode(jsonEncode(map)))
        .replaceAll('=', '');
    return '$kCardPageUrl#$encoded';
  }

  Future<void> _shareContact() async {
    Get.back();
    try {
      final data = ProfileStore.to.profile.value;
      if (data.fullName.trim().isEmpty) {
        _snack('home_share_no_details_title'.tr, 'home_share_no_details_link'.tr);
        return;
      }
      final link = _buildCardLink(data);

      await SharePlus.instance.share(
        ShareParams(
          text: 'home_share_text'.trParams({'link': link}),
          subject: 'home_share_subject'.trParams({'name': data.fullName.trim()}),
          sharePositionOrigin: shareOrigin(),
        ),
      );
      FirebaseAnalytics.instance.logEvent(
        name: 'card_shared',
        parameters: {'method': 'link'},
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st, reason: 'share link');
      _snack('home_share_failed_title'.tr, 'home_try_again'.tr);
    }
  }

  Future<void> _shareImage() async {
    Get.back();
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(cardImage.path)],
          sharePositionOrigin: shareOrigin(),
        ),
      );
      FirebaseAnalytics.instance.logEvent(
        name: 'card_shared',
        parameters: {'method': 'image'},
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st, reason: 'share image');
      _snack('home_share_failed_title'.tr, 'home_try_again'.tr);
    }
  }

  Future<void> _saveToGallery() async {
    Get.back();
    try {
      if (!await Gal.hasAccess()) {
        if (!await Gal.requestAccess()) {
          _snack('home_share_permission_title'.tr, 'home_share_permission_message'.tr);
          return;
        }
      }
      await Gal.putImage(cardImage.path);
      FirebaseAnalytics.instance.logEvent(name: 'card_saved_to_gallery');
      _snack('home_share_saved_title'.tr, 'home_share_saved_message'.tr);
    } catch (e, st) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'save card to gallery');
      _snack('home_share_save_failed_title'.tr, 'home_try_again'.tr);
    }
  }

  void _showQr() {
    Get.back();
    final entry = QrStore.defaultEntry;
    final profile = loadSavedQrProfile();
    if (profile == null) {
      _snack('home_share_no_details_title'.tr, 'home_share_no_details_qr'.tr);
      return;
    }
    FirebaseAnalytics.instance.logEvent(name: 'qr_shown');
    Get.to(
          () => QrPreviewScreen(
        profile: profile,
        qrOnly: true,
        style: entry?.style ?? QrStyles.classic,
      ),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'home_share_sheet_title'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.titleDark,
              ),
            ),
            const SizedBox(height: 8),
            _Option(
              icon: Icons.share,
              label: 'home_share_option_link'.tr,
              onTap: _shareContact,
            ),
            _Option(
              icon: Icons.image_outlined,
              label: 'home_share_option_image'.tr,
              onTap: _shareImage,
            ),
            _Option(
              icon: Icons.download_rounded,
              label: 'home_share_option_gallery'.tr,
              onTap: _saveToGallery,
            ),
            _Option(
              icon: Icons.qr_code_2_rounded,
              label: 'home_share_option_qr'.tr,
              onTap: _showQr,
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.titleDark),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.titleDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}