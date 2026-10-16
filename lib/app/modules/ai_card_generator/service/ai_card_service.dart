import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/services/ai_card_prompt_builder.dart';
import '../../../core/services/ai_frame_card_builder.dart';
import '../../../core/services/gemini_card_service.dart';
import '../../profile/model/profile_model.dart';
import '../../profile_setup/service/profile_store.dart';
import '../model/generated_card.dart';

const Map<String, String> kReadyTemplateAssets = {
  // Example:
  'ai_test': 'assets/images/ai_business_card_template.jpg',
  'ai_test2': 'assets/images/ai_business_card_template2.jpg',
  'ai_test3': 'assets/images/ai_business_card_template3.jpg',
  'ai_test4': 'assets/images/ai_business_card_template4.jpg',
  'ai_test5': 'assets/images/ai_business_card_template5.jpg',
};

class AiCardService {
  Future<GeneratedCard> generateCard({
    required String prompt,
    File? referenceImage,
    String? templateId,
    ProfileModel? profile,
  }) async {
    // ---------------------------------------------------------------
    // ONE COMPLETE REFERENCE
    // ---------------------------------------------------------------
    final reference = await _loadReference(
      referenceImage: referenceImage,
      templateId: templateId,
    );

    if (reference == null) {
      debugPrint(
        'AI CARD SERVICE: no reference resolved '
        '(referenceImage=$referenceImage, templateId=$templateId)',
      );
      throw const GeminiException(
        'Choose a template or upload an image first.',
      );
    }

    // The card's text: the auto-filled profile, else the details from
    // onboarding. The prompt and reference image only set the style.
    final onboarding = ProfileStore.to.profile.value;
    final details = profile != null
        ? CardDetails.fromProfile(profile)
        : CardDetails.fromUserProfile(onboarding);

    if (kDebugMode) {
      debugPrint(
        '--- AI CARD (frames) --- kind: ${reference.kind}, '
        'mime: ${reference.mime}, bytes: ${reference.bytes.length}, '
        'prompt: "$prompt"',
      );
    }

    // Two Gemini calls (front and back frames); the details are laid on
    // them and the card is saved to My Cards — see AiFrameCardBuilder.
    final design = await AiFrameCardBuilder.create(
      style: reference.bytes,
      styleMime: reference.mime,
      kind: reference.kind,
      details: details,
      userPrompt: prompt,
      logo: onboarding.hasLogo ? onboarding.logoBytes : null,
    );

    return GeneratedCard(
      frontImagePath: design.path,
      backImagePath: design.backPath ?? design.path,
    );
  }

  Future<_Reference?> _loadReference({
    File? referenceImage,
    String? templateId,
  }) async {
    // ---------------------------------------------------------------
    // UPLOADED IMAGE
    // ---------------------------------------------------------------
    if (referenceImage != null) {
      final bytes = await referenceImage.readAsBytes();

      debugPrint(
        'AI CARD SERVICE: using UPLOADED image '
        '(${referenceImage.path}, ${bytes.length} bytes)',
      );

      return _Reference(
        bytes: bytes,
        mime: _mimeFromPath(referenceImage.path),
        kind: ReferenceKind.upload,
      );
    }

    // ---------------------------------------------------------------
    // READY TEMPLATE
    // ---------------------------------------------------------------
    if (templateId != null && templateId.isNotEmpty) {
      final asset =
          kReadyTemplateAssets[templateId] ??
          (templateId.contains('/') || templateId.contains('.')
              ? templateId
              : null);

      if (asset == null) {
        debugPrint(
          'AI CARD SERVICE: templateId "$templateId" did not resolve '
          'to any known asset',
        );
        return null;
      }

      try {
        final data = await rootBundle.load(asset);

        debugPrint(
          'AI CARD SERVICE: using TEMPLATE image '
          '($asset, ${data.lengthInBytes} bytes)',
        );

        return _Reference(
          bytes: data.buffer.asUint8List(),
          mime: _mimeFromPath(asset),
          kind: ReferenceKind.template,
        );
      } catch (e, st) {
        debugPrint('AI CARD SERVICE: failed to load asset "$asset"');
        debugPrint('error: $e');
        debugPrint('stack: $st');
        return null;
      }
    }

    return null;
  }

  String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();

    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'webp':
        return 'image/webp';

      case 'heic':
        return 'image/heic';

      default:
        return 'image/png';
    }
  }
}

class _Reference {
  final Uint8List bytes;
  final String mime;
  final ReferenceKind kind;

  const _Reference({
    required this.bytes,
    required this.mime,
    required this.kind,
  });
}

