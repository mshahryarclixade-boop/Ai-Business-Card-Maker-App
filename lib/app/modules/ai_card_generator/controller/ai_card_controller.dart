import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../../core/services/gemini_card_service.dart' show GeminiException;
import '../../../core/services/recent_designs_service.dart';
import '../../../core/services/app_review_service.dart';
import '../../../core/services/internet_connectivity_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../paywall/services/credits_gate.dart';
import '../../../core/widgets/connection_interrupted_dialog.dart';
import '../../profile/model/profile_model.dart';
import '../../profile/service/profile_repository.dart';
import '../model/generated_card.dart';
import '../service/ai_card_service.dart';
import '../../../core/translations/tr_extension.dart';

class AiCardController extends GetxController {
  static const int promptMaxLength = 200;

  final Rx<File?> referenceImage = Rx<File?>(null);
  final RxString selectedTemplateId = ''.obs;
  final promptController = TextEditingController();

  String? _appliedInitialPrompt;
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

  /// Adds an existing AI card image to the reference image section.
  void applyInitialImage(File? image) {
    if (image == null || _appliedInitialImagePath == image.path) return;

    _appliedInitialImagePath = image.path;
    referenceImage.value = image;
  }

  Future<void> pickReferenceImage([
    ImageSource source = ImageSource.gallery,
  ]) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);

      if (picked == null) return;

      referenceImage.value = File(picked.path);
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'AI card reference image selection',
      );

      debugPrint('AI CARD PICK IMAGE ERROR: $e');
      debugPrint('$st');

      Get.snackbar(
        source == ImageSource.camera
            ? 'ai_card_camera_unavailable_title'.tr
            : 'ai_card_gallery_unavailable_title'.tr,
        source == ImageSource.camera
            ? 'ai_card_camera_permission_message'.tr
            : 'ai_card_gallery_permission_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  void clearReferenceImage() => referenceImage.value = null;

  void selectReadyTemplate(String templateId) {
    selectedTemplateId.value = selectedTemplateId.value == templateId
        ? ''
        : templateId;
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
          'ai_card_no_profile_title'.tr,
          'ai_card_no_profile_message'.tr,
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

  bool _checkingCredits = false;

  Future<void> generate() async {
    if (isGenerating.value) return;

    if (!canGenerate) {
      Get.snackbar(
        'ai_card_nothing_to_generate_title'.tr,
        'ai_card_nothing_to_generate_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    // Check actual internet access before starting AI generation.
    final hasInternet = await InternetConnectivityService.hasInternetAccess();

    if (!hasInternet) {
      await showConnectionInterruptedDialog();
      return;
    }

    // Plan limit: no-op unless Remote Config `credits_enabled` is on.
    final aiCardCost = RemoteConfigService().creditCosts.aiCard;
    if (_checkingCredits) return;
    _checkingCredits = true;
    final allowed = await CreditGate.canUse(
      cost: aiCardCost,
      source: 'ai_card',
    ).whenComplete(() => _checkingCredits = false);
    // Re-check: another tap may have started generating while we waited.
    if (!allowed || isGenerating.value) return;

    isGenerating.value = true;
    generatedCard.value = null;
    errorMessage.value = '';

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
        templateId: selectedTemplateId.value.isEmpty
            ? null
            : selectedTemplateId.value,
        profile: autoFillProfile.value ? autoFillProfileData.value : null,
      );

      debugPrint('AI CARD: generation SUCCESS');

      // Charged only now that a card was actually delivered.
      await CreditGate.spend(cost: aiCardCost, source: 'ai_card');

      await FirebaseAnalytics.instance.logEvent(name: 'card_generated');

      // Already saved to My Cards (editable) by AiFrameCardBuilder.
      debugPrint('front: ${generatedCard.value?.frontImagePath}');
      debugPrint('back: ${generatedCard.value?.backImagePath}');

      // Request a native review after successful generation.
      // Android may decide not to display the dialog.
      debugPrint('REVIEW: AI card generation succeeded');
      await AppReviewService.requestNativeReview();
      debugPrint('REVIEW: AI review request returned');
    } on GeminiException catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'AI card Gemini generation',
      );

      await FirebaseAnalytics.instance.logEvent(name: 'card_generation_failed');

      debugPrint('========== AI CARD GENERATION ERROR (Gemini) ==========');
      debugPrint('message: ${e.message}');
      debugPrint('$stackTrace');
      debugPrint('========================================================');

      _fail(e.message);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'AI card unknown generation error',
      );

      await FirebaseAnalytics.instance.logEvent(name: 'card_generation_failed');

      debugPrint('========== AI CARD GENERATION ERROR (Unknown) ==========');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('=========================================================');

      _fail('ai_card_generate_failed_message'.tr);
    } finally {
      isGenerating.value = false;
    }
  }

  void _fail(String message) {
    errorMessage.value = message;

    Get.snackbar(
      'ai_card_generate_failed_title'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
  }

  Future<void> regenerate() => generate();

  Future<void> saveCardToGallery() async {
    final card = generatedCard.value;
    if (card == null || isSaving.value) return;

    // Same card re-saved/re-shared is charged once (see CreditGate).
    final exportKey = 'ai_card_export:${card.frontImagePath}';
    final exportCost = RemoteConfigService().creditCosts.export;
    if (!await CreditGate.canUse(
      cost: exportCost,
      source: 'ai_card_export',
      dedupeKey: exportKey,
    )) {
      return;
    }

    isSaving.value = true;

    try {
      final hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        final granted = await Gal.requestAccess();

        if (!granted) {
          Get.snackbar(
            'ai_card_permission_needed_title'.tr,
            'ai_card_save_permission_message'.tr,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(15),
          );
          return;
        }
      }

      await Gal.putImage(card.frontImagePath, album: 'AI Business Card');

      await Gal.putImage(card.backImagePath, album: 'AI Business Card');

      await FirebaseAnalytics.instance.logEvent(name: 'card_saved_to_gallery');
      await CreditGate.spend(
        cost: exportCost,
        source: 'ai_card_export',
        dedupeKey: exportKey,
      );

      Get.snackbar(
        'ai_card_saved_title'.tr,
        'ai_card_saved_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } on GalException catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'AI card gallery save',
      );

      debugPrint('GAL SAVE ERROR: ${e.type} - ${e.platformException}');

      Get.snackbar(
        'ai_card_save_failed_title'.tr,
        'ai_card_save_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'AI card gallery save unknown error',
      );

      debugPrint('GAL SAVE UNKNOWN ERROR: $e');
      debugPrint('$st');

      Get.snackbar(
        'ai_card_save_failed_title'.tr,
        'ai_card_save_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Shares the front and back generated images via the system share sheet.
  Future<void> shareCard() async {
    final card = generatedCard.value;
    if (card == null || isSharing.value) return;

    final exportKey = 'ai_card_export:${card.frontImagePath}';
    final exportCost = RemoteConfigService().creditCosts.export;
    if (!await CreditGate.canUse(
      cost: exportCost,
      source: 'ai_card_export',
      dedupeKey: exportKey,
    )) {
      return;
    }

    isSharing.value = true;

    try {
      await Share.shareXFiles([
        XFile(card.frontImagePath),
        XFile(card.backImagePath),
      ], text: 'ai_card_share_text'.tr);
      await CreditGate.spend(
        cost: exportCost,
        source: 'ai_card_export',
        dedupeKey: exportKey,
      );

      await FirebaseAnalytics.instance.logEvent(name: 'card_shared');
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'AI card sharing',
      );

      debugPrint('AI CARD SHARE ERROR: $e');
      debugPrint('$st');

      Get.snackbar(
        'ai_card_share_failed_title'.tr,
        'ai_card_share_failed_message'.tr,
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
