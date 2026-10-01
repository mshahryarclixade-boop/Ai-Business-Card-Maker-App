import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../custom_create/controller/card_editor_controller.dart';
import '../../custom_create/view/card_editor_view.dart';
import '../../paywall/view/paywall_view.dart';
import '../model/qr_code_builder.dart';
import '../model/qr_profile_data.dart';
import '../service/qr_generator_service.dart';


/// Matches the "Preview" screen: purple card with the QR, name + company
/// underneath, a "Create a Business Card" upsell, and Download/Share.
class QrPreviewScreen extends StatelessWidget {
  final QrProfileData profile;
  const QrPreviewScreen({super.key, required this.profile});

  Future<Uint8List> _pngBytes() =>
      QrGeneratorService().generatePngBytes(profile, size: 1024);

  Future<void> _download(BuildContext context) async {
    final bytes = await _pngBytes();
    final dir = await getApplicationDocumentsDirectory();
    final file = await _writeBytes(dir.path, bytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${file.path}')),
      );
    }
  }

  Future<void> _share() async {
    final bytes = await _pngBytes();
    final dir = await getApplicationDocumentsDirectory();
    final file = await _writeBytes(dir.path, bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<File> _writeBytes(String dirPath, Uint8List bytes) async {
    final file = File('$dirPath/qr_${DateTime.now().millisecondsSinceEpoch}.png');
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
      body: Padding(
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
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
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
                  child: const Icon(Icons.badge_outlined, color: Color(0xFF444494)),
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
                  // UPDATED: Generate the same QR shown on this preview.
                  final bytes = await _pngBytes();

                  final dir = await getApplicationDocumentsDirectory();
                  final file = await _writeBytes(dir.path, bytes);

                  // UPDATED: Create/register the editor controller before opening it.
                  final editorController = Get.put(CardEditorController());

                  // UPDATED: Put the generated QR directly onto the editor canvas.
                  editorController.addGeneratedQrToCanvas(file);

                  Get.to(
                        () => const CardEditorView(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
            ),
            const SizedBox(height: 50),
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
            SizedBox(
              width: 333,
              height: 50,
              child: OutlinedButton(
                onPressed: _share,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF444494),
                  side: const BorderSide(color: Color(0xFF444494), width: 1),
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