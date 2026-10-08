import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:get_storage/get_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../custom_create/view/card_editor_view.dart';
import '../../paywall/view/paywall_view.dart';
import '../../profile_setup/service/profile_store.dart';
import '../model/qr_code_builder.dart';
import '../model/qr_profile_data.dart';
import '../service/qr_generator_service.dart';

const String _kQrFormKey = 'qr_form_data';

String _str(dynamic v) => v is String ? v : '';

QrProfileData? loadSavedQrProfile() {
  final raw = GetStorage().read<String>(_kQrFormKey);

  if (raw != null) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final links = <SocialLink>[];
      for (final item in (m['links'] as List?) ?? const []) {
        if (item is Map) {
          links.add(
            SocialLink(platform: _str(item['platform']), url: _str(item['url'])),
          );
        }
      }
      final saved = QrProfileData(
        fullName: _str(m['fullName']),
        phoneNumber: _str(m['phone']),
        emailAddress: _str(m['email']),
        companyName: _str(m['company']),
        designation: _str(m['designation']),
        websiteUrl: _str(m['website']),
        country: _str(m['country']),
        city: _str(m['city']),
        socialLinks: links,
      );
      if (saved.isValid) return saved;
    } catch (_) {
      // Unreadable saved data: fall back to the setup details below.
    }
  }

  final d = ProfileStore.to.profile.value;
  final fallback = QrProfileData(
    fullName: d.fullName.trim(),
    phoneNumber: d.phone.trim(),
    emailAddress: d.email.trim(),
    companyName: d.companyName.trim(),
    designation: d.designation.trim(),
    websiteUrl: d.website.trim(),
    country: '',
    city: '',
    socialLinks: const [],
  );
  return fallback.isValid ? fallback : null;
}

/// Download/Share.
class QrPreviewScreen extends StatelessWidget {
  final QrProfileData profile;
  final bool qrOnly;

  const QrPreviewScreen({
    super.key,
    required this.profile,
    this.qrOnly = false,
  });

  Future<Uint8List> _pngBytes() =>
      QrGeneratorService().generatePngBytes(profile, size: 1024);

  Future<void> _download(BuildContext context) async {
    final bytes = await _pngBytes();
    final dir = await getTemporaryDirectory();
    final file = await _writeBytes(dir.path, bytes);

    String message;
    try {
      final allowed = await Gal.hasAccess() || await Gal.requestAccess();
      if (!allowed) {
        message = 'Allow photo access to save the QR code.';
      } else {
        await Gal.putImage(file.path);
        message = 'QR code saved to your gallery.';
      }
    } catch (_) {
      message = 'Could not save the QR code. Please try again.';
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _share() async {
    try {
      final bytes = await _pngBytes();
      final dir = await getTemporaryDirectory();
      final file = await _writeBytes(dir.path, bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Scan this QR code to save my contact.',
          subject: '${profile.fullName} - Contact QR Code',
        ),
      );
    } catch (_) {
      Get.snackbar(
        'Could not share',
        'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  Future<File> _writeBytes(String dirPath, Uint8List bytes) async {
    final file =
    File('$dirPath/qr_${DateTime.now().millisecondsSinceEpoch}.png');
    return file.writeAsBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.titleDark),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Preview',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.titleDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Get.to(
                      () => const PaywallView(),
                  transition: Transition.rightToLeft,
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.cardWhite,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const FaIcon(
                  FontAwesomeIcons.crown,
                  size: 18,
                  color: Color(0xFFF5A623),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(35, 32, 35, 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(45),
              decoration: BoxDecoration(
                color: const Color(0xFF3F3D9E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: QrImageView(
                        data: buildVCard(profile),
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        size: 200,
                        gapless: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (profile.companyName.isNotEmpty)
                    Text(
                      'Company • ${profile.companyName}',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (!qrOnly) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xABD9D9FF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.badge_outlined,
                        color: Color(0xFF444494)),
                  ),
                  title: const Text(
                    'Create a Business Card',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                  subtitle: const Text(
                    'Use this info to design your card',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    // Same QR as shown on this preview.
                    final bytes = await _pngBytes();
                    final dir = await getApplicationDocumentsDirectory();
                    final file = await _writeBytes(dir.path, bytes);

                    // The user's saved card (the one shown on Home).
                    final designs = Get.find<RecentDesignsService>().designs;
                    final design = designs.isEmpty ? null : designs.first;

                    // The editor loads the card first, then adds the QR.
                    Get.to(
                          () => CardEditorView(design: design, qrToAdd: file),
                      transition: Transition.rightToLeft,
                    );
                  },
                ),
              ),
            ],
            SizedBox(height: qrOnly ? 30 : 50),

            // Download: only on the normal preview.
            if (!qrOnly) ...[
              SizedBox(
                width: 333,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _download(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Download'),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Share: shown on both screens. Filled when it is the only button.
            SizedBox(
              width: 333,
              height: 50,
              child: qrOnly
                  ? ElevatedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
                  : OutlinedButton(
                onPressed: _share,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF444494),
                  side: const BorderSide(
                      color: Color(0xFF444494), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}