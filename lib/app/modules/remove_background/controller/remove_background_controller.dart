import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../service/remove_bg_service.dart';
import '../../../core/translations/tr_extension.dart';

/// The 4 screens described in the flow:
/// initial (take/upload) -> confirm (retake or accept) -> processing -> result
enum RemoveBgState { initial, confirm, processing, result }

class RemoveBackgroundController extends GetxController {
  RemoveBackgroundController({RemoveBgService? service})
      : _service = service ?? RemoveBgService();

  final RemoveBgService _service;
  final ImagePicker _picker = ImagePicker();

  final Rx<RemoveBgState> state = RemoveBgState.initial.obs;

  /// The photo the user just took / picked, shown on the confirm screen.
  final Rx<File?> pickedImage = Rx<File?>(null);

  /// PNG bytes returned by remove.bg (transparent background).
  final Rx<Uint8List?> resultBytes = Rx<Uint8List?>(null);

  final RxBool isDownloading = false.obs;
  final RxBool isSharing = false.obs;

  // ---- Step 1: capture / pick -------------------------------------------

  Future<void> takePicture() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (file == null) return;
    pickedImage.value = File(file.path);
    state.value = RemoveBgState.confirm;
  }

  Future<void> uploadFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (file == null) return;
    pickedImage.value = File(file.path);
    state.value = RemoveBgState.confirm;
  }

  // ---- Step 2: confirm / retake ------------------------------------------

  void retake() {
    pickedImage.value = null;
    state.value = RemoveBgState.initial;
  }

  /// User tapped the checkmark on the confirm screen -> kick off processing.
  Future<void> confirmAndProcess() async {
    final image = pickedImage.value;
    if (image == null) return;

    state.value = RemoveBgState.processing;

    try {
      final bytes = await _service.removeBackground(image);
      resultBytes.value = bytes;
      state.value = RemoveBgState.result;
    } on RemoveBgException catch (e) {
      state.value = RemoveBgState.confirm;
      Get.snackbar(
        'remove_bg_failed_title'.tr,
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      state.value = RemoveBgState.confirm;
      Get.snackbar(
        'remove_bg_error_title'.tr,
        'remove_bg_try_again_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ---- Step 4: result actions ---------------------------------------------

  /// Writes the resulting PNG (transparent bg) to a temp file and returns it.
  /// Reused by both download and share.
  Future<File> _writeResultToTempFile() async {
    final bytes = resultBytes.value;
    if (bytes == null) {
      throw StateError('No processed image to save.');
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/no_bg_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Saves the transparent PNG to the device's photo gallery using `gal`.
  Future<void> downloadToGallery() async {
    if (isDownloading.value) return;
    final bytes = resultBytes.value;
    if (bytes == null) return;

    isDownloading.value = true;
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          Get.snackbar(
            'remove_bg_permission_needed_title'.tr,
            'remove_bg_save_permission_message'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      await Gal.putImageBytes(
        bytes,
        name: 'no_bg_${DateTime.now().millisecondsSinceEpoch}',
        album: 'AI Business Card Maker',
      );

      Get.snackbar(
        'remove_bg_saved_title'.tr,
        'remove_bg_saved_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on GalException catch (e) {
      Get.snackbar(
        'remove_bg_save_failed_title'.tr,
        e.type.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'remove_bg_save_failed_title'.tr,
        'remove_bg_save_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  /// Opens the native share sheet for the transparent PNG via `share_plus`.
  Future<void> shareResult() async {
    if (isSharing.value) return;
    if (resultBytes.value == null) return;

    isSharing.value = true;
    try {
      final file = await _writeResultToTempFile();
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'remove_bg_share_text'.tr,
      );

      if (result.status == ShareResultStatus.dismissed) {
        // User closed the share sheet without picking a target — no-op.
      }
    } catch (_) {
      Get.snackbar(
        'remove_bg_share_failed_title'.tr,
        'remove_bg_try_again_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSharing.value = false;
    }
  }

  /// Reset everything and go back to the first screen.
  void reset() {
    pickedImage.value = null;
    resultBytes.value = null;
    state.value = RemoveBgState.initial;
  }
}