import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/gemini_card_service.dart' show GeminiException;
import '../../profile/model/profile_model.dart';
import '../../profile/service/profile_repository.dart';
import '../model/generated_card.dart';
import '../service/ai_card_service.dart';
import '../../../core/services/recent_designs_service.dart';

class AiCardController extends GetxController {
  static const int promptMaxLength = 200;

  final Rx<File?> referenceImage = Rx<File?>(null);
  final RxString selectedTemplateId = ''.obs;
  final promptController = TextEditingController();

  String? _appliedInitialPrompt;

  /// Existing AI card ki image (Edit tap se aayi hui) sirf ek dafa apply
  /// hoti hai, taake rebuild par user ki hataayi hui image wapas na aaye.
  String? _appliedInitialImagePath;

  final RxBool autoFillProfile = false.obs;
  final Rx<ProfileModel?> autoFillProfileData = Rx<ProfileModel?>(null);

  final RxBool isGenerating = false.obs;
  final Rx<GeneratedCard?> generatedCard = Rx<GeneratedCard?>(null);

  final RxBool isSaving = false.obs;
  final RxBool isSharing = false.obs;

  /// Empty when there is no error. The preview screen can show this.
  final RxString errorMessage = ''.obs;

  final ImagePicker _picker = ImagePicker();

  final RecentDesignsService _recentDesignsService =
  Get.find<RecentDesignsService>();

  /// Home screen ka prompt "Enter Prompt" field main daalta hai.
  void applyInitialPrompt(String? prompt) {
    final text = (prompt ?? '').trim();
    if (text.isEmpty || _appliedInitialPrompt == text) return;

    _appliedInitialPrompt = text;
    promptController.text = text.length > promptMaxLength
        ? text.substring(0, promptMaxLength)
        : text;
    promptController.selection = TextSelection.collapsed(
      offset: promptController.text.length,
    );
  }

  /// Existing AI card ki image ko reference image section mein daalta hai
  /// (card detail screen ke Edit button se aane par).
  void applyInitialImage(File? image) {
    if (image == null || _appliedInitialImagePath == image.path) return;

    _appliedInitialImagePath = image.path;
    referenceImage.value = image;
  }

  /// [source] decides whether the image comes from the camera or the
  /// gallery (the view asks the user via a bottom sheet).
  Future<void> pickReferenceImage([
    ImageSource source = ImageSource.gallery,
  ]) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;
      referenceImage.value = File(picked.path);
    } catch (e, st) {
      // Camera/gallery permission denied or camera unavailable.
      debugPrint('AI CARD PICK IMAGE ERROR: $e');
      debugPrint('$st');
      Get.snackbar(
        source == ImageSource.camera ? 'Camera unavailable' : 'Gallery unavailable',
        source == ImageSource.camera
            ? 'Allow camera access to take a photo.'
            : 'Allow photo access to pick an image.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  void clearReferenceImage() => referenceImage.value = null;

  void selectReadyTemplate(String templateId) {
    selectedTemplateId.value =
    selectedTemplateId.value == templateId ? '' : templateId;
  }

  void resetPrompt() {
    promptController.clear();
    _appliedInitialPrompt = null;
  }

  void toggleAutoFill(bool value) {
    if (value) {
      final profile = ProfileRepository.getSavedProfile();
      if (profile == null) {
        Get.snackbar(
          'No saved profile',
          'Save your profile first to use auto-fill.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
        );
        return;
      }
      autoFillProfileData.value = profile;
    } else {
      autoFillProfileData.value = null;
    }
    autoFillProfile.value = value;
  }

  bool get canGenerate =>
      promptController.text.trim().isNotEmpty ||
          referenceImage.value != null ||
          selectedTemplateId.value.isNotEmpty;

  Future<void> generate() async {
    if (isGenerating.value) return; // ignore double taps

    if (!canGenerate) {
      Get.snackbar(
        'Nothing to generate from',
        'Upload a reference image, pick a template, or describe your design.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    isGenerating.value = true;
    generatedCard.value = null;
    errorMessage.value = '';

    // Debug: confirm what inputs are actually being sent.
    debugPrint('========== AI CARD GENERATE() CALLED ==========');
    debugPrint('prompt: "${promptController.text.trim()}"');
    debugPrint('referenceImage: ${referenceImage.value?.path}');
    debugPrint('selectedTemplateId: "${selectedTemplateId.value}"');
    debugPrint('autoFillProfile: ${autoFillProfile.value}');
    debugPrint('================================================');

    try {
      generatedCard.value = await AiCardService().generateCard(
        prompt: promptController.text.trim(),
        referenceImage: referenceImage.value,
        templateId:
        selectedTemplateId.value.isEmpty ? null : selectedTemplateId.value,
        profile: autoFillProfile.value ? autoFillProfileData.value : null,
      );

      debugPrint('AI CARD: generation SUCCESS');
      debugPrint('front: ${generatedCard.value?.frontImagePath}');
      debugPrint('back: ${generatedCard.value?.backImagePath}');
      debugPrint(
        'editable: front=${generatedCard.value?.hasEditableFront} '
            'back=${generatedCard.value?.hasEditableBack}',
      );

      // Save right after a successful generation, using THIS
      // generation's paths — not a stale/previous one.
      try {
        final card = generatedCard.value!;
        await _recentDesignsService.saveAiCard(
          frontTempPath: card.frontImagePath,
          backTempPath: card.backImagePath,
          frontBackgroundTempPath: card.frontBackgroundPath,
          backBackgroundTempPath: card.backBackgroundPath,
          frontElements: card.frontElements,
          backElements: card.backElements,
        );
      } catch (e) {
        debugPrint('AI CARD: failed to save to My Cards list: $e');
      }
    } on GeminiException catch (e, stackTrace) {
      debugPrint('========== AI CARD GENERATION ERROR (Gemini) ==========');
      debugPrint('message: ${e.message}');
      debugPrint('$stackTrace');
      debugPrint('========================================================');
      _fail(e.message);
    } catch (e, stackTrace) {
      debugPrint('========== AI CARD GENERATION ERROR (Unknown) ==========');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('=========================================================');
      _fail('Could not generate the card. Please try again.');
    } finally {
      isGenerating.value = false;
    }
  }

  void _fail(String message) {
    errorMessage.value = message;
    Get.snackbar(
      'Could not generate card',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
  }

  Future<void> regenerate() => generate();

  Future<void> saveCardToGallery() async {
    final card = generatedCard.value;
    if (card == null) return;

    if (isSaving.value) return; // ignore double taps

    isSaving.value = true;

    try {
      // Check/request gallery access first.
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          Get.snackbar(
            'Permission needed',
            'Allow photo/gallery access to save your card.',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(15),
          );
          return;
        }
      }

      // Save both sides. Album name groups them together in the gallery.
      await Gal.putImage(card.frontImagePath, album: 'AI Business Card');
      await Gal.putImage(card.backImagePath, album: 'AI Business Card');

      Get.snackbar(
        'Saved',
        'Card saved to your gallery.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } on GalException catch (e) {
      debugPrint('GAL SAVE ERROR: ${e.type} - ${e.platformException}');
      Get.snackbar(
        'Could not save',
        'Something went wrong while saving to gallery.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } catch (e, st) {
      debugPrint('GAL SAVE UNKNOWN ERROR: $e');
      debugPrint('$st');
      Get.snackbar(
        'Could not save',
        'Something went wrong while saving to gallery.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Shares both the front and back generated images together via the
  /// system share sheet.
  Future<void> shareCard() async {
    final card = generatedCard.value;
    if (card == null) return;

    if (isSharing.value) return; // ignore double taps

    isSharing.value = true;

    try {
      await Share.shareXFiles(
        [
          XFile(card.frontImagePath),
          XFile(card.backImagePath),
        ],
        text: 'Check out my AI-generated business card!',
      );
    } catch (e, st) {
      debugPrint('AI CARD SHARE ERROR: $e');
      debugPrint('$st');
      Get.snackbar(
        'Could not share',
        'Something went wrong while sharing the card.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } finally {
      isSharing.value = false;
    }
  }

  @override
  void onClose() {
    promptController.dispose();
    super.onClose();
  }
}