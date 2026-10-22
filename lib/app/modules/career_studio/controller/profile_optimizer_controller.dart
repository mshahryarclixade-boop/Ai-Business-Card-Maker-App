import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';

import '../service/career_ai_service.dart';
import '../view/profile_analyzing_view.dart';
import '../../../core/translations/tr_extension.dart';

enum ProfileSource { pdf, images, text }

class ProfileOptimizerController extends GetxController {
  static const maxImages = 5;

  final source = ProfileSource.pdf.obs;
  final pdf = Rxn<PlatformFile>();
  final images = <XFile>[].obs;
  final sections = TextEditingController();

  final _picker = ImagePicker();

  void selectSource(ProfileSource s) => source.value = s;

  Future<void> pickPdf() async {
    selectSource(ProfileSource.pdf);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    pdf.value = result.files.single;
  }

  Future<void> pickImages() async {
    selectSource(ProfileSource.images);

    final remaining = maxImages - images.length;
    if (remaining <= 0) {
      _showLimitMessage();
      return;
    }

    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    images.addAll(picked.take(remaining));
    if (picked.length > remaining) _showLimitMessage();
  }

  void removeImage(int index) => images.removeAt(index);

  void analyze() {
    switch (source.value) {
      case ProfileSource.pdf:
        if (pdf.value == null) return _warn('career_optimizer_no_pdf_title'.tr, 'career_optimizer_no_pdf_message'.tr);
      case ProfileSource.images:
        if (images.isEmpty) return _warn('career_optimizer_no_images_title'.tr, 'career_optimizer_no_images_message'.tr);
      case ProfileSource.text:
        if (sections.text.trim().isEmpty) return _warn('career_optimizer_no_text_title'.tr, 'career_optimizer_no_text_message'.tr);
    }

    Get.to(
          () => const ProfileAnalyzingView(),
      transition: Transition.rightToLeft,
    );
  }

  /// Largest upload sent to the AI (callable requests cap at ~10 MB).
  static const _maxUploadBytes = 7 * 1024 * 1024;

  /// What to scan: the chosen source, read and encoded for the AI.
  Future<ProfileScanInput> scanInput() async {
    switch (source.value) {
      case ProfileSource.text:
        return ProfileScanInput(text: sections.text.trim());
      case ProfileSource.pdf:
        final path = pdf.value?.path;
        final bytes = path == null ? null : await File(path).readAsBytes();
        if (bytes == null || bytes.length > _maxUploadBytes) {
          throw GeminiException('career_ai_error_rejected'.tr);
        }
        return ProfileScanInput(pdf: base64Encode(bytes));
      case ProfileSource.images:
        var total = 0;
        final out = <({String base64, String mime})>[];
        for (final x in images) {
          final bytes = await x.readAsBytes();
          total += bytes.length;
          if (total > _maxUploadBytes) {
            throw GeminiException('career_ai_error_rejected'.tr);
          }
          final mime = x.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg';
          out.add((base64: base64Encode(bytes), mime: mime));
        }
        return ProfileScanInput(images: out);
    }
  }

  void _showLimitMessage() =>
      _warn(
        'career_optimizer_limit_title'.tr,
        'career_optimizer_limit_message'.trParams({'count': maxImages}),
      );

  void _warn(String title, String message) => Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(15),
  );

  @override
  void onClose() {
    sections.dispose();
    super.onClose();
  }
}