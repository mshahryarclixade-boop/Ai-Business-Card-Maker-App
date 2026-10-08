import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/ai_card_prompt_builder.dart';
import '../../../core/services/editable_card_builder.dart';
import '../../../core/services/gemini_card_service.dart';
import '../../custom_create/model/card_element_model.dart';
import '../../profile/model/profile_model.dart';
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

    final details = profile == null
        ? null
        : CardDetails.fromProfile(profile);

    // ---------------------------------------------------------------
    // FRONT PROMPT
    // ---------------------------------------------------------------
    final frontPrompt = AiCardPromptBuilder.build(
      kind: reference.kind,
      side: CardSide.front,
      userPrompt: prompt,
      details: details,
    );

    // ---------------------------------------------------------------
    // BACK PROMPT
    // ---------------------------------------------------------------
    final backPrompt = AiCardPromptBuilder.build(
      kind: reference.kind,
      side: CardSide.back,
      userPrompt: prompt,
      details: details,
    );

    // Prints the exact prompts sent to Gemini in debug builds.
    if (kDebugMode) {
      debugPrint(
        '--- AI CARD REFERENCE ---\n'
            'kind: ${reference.kind}\n'
            'mime: ${reference.mime}\n'
            'bytes: ${reference.bytes.length}',
      );

      debugPrint(
        '--- AI CARD PROMPT (front) ---\n$frontPrompt',
      );

      debugPrint(
        '--- AI CARD PROMPT (back) ---\n$backPrompt',
      );
    }

    // ---------------------------------------------------------------
    // GENERATE FRONT + BACK
    // ---------------------------------------------------------------
    final service = GeminiCardService();

    Uint8List frontBytes;
    Uint8List backBytes;

    try {
      final results = await Future.wait([
        service.generateCard(
          prompt: frontPrompt,
          referenceBytes: reference.bytes,
          referenceMime: reference.mime,
        ),
        service.generateCard(
          prompt: backPrompt,
          referenceBytes: reference.bytes,
          referenceMime: reference.mime,
        ),
      ]);

      frontBytes = results[0];
      backBytes = results[1];

      debugPrint(
        'AI CARD SERVICE: generateCard calls returned '
            '(front=${frontBytes.length} bytes, back=${backBytes.length} bytes)',
      );
    } catch (e, st) {
      debugPrint('========== GEMINI CALL FAILED ==========');
      debugPrint('error: $e');
      debugPrint('stack: $st');
      debugPrint('=========================================');
      rethrow;
    }

    // ---------------------------------------------------------------
    // SAVE BOTH GENERATED SIDES SEPARATELY
    // ---------------------------------------------------------------
    final frontPath = await _saveToTempFile(
      frontBytes,
      side: 'front',
    );

    final backPath = await _saveToTempFile(
      backBytes,
      side: 'back',
    );

    debugPrint(
      'AI CARD SERVICE: saved files '
          '(front=$frontPath, back=$backPath)',
    );

    // ---------------------------------------------------------------
    // EDITABLE VERSION (text-free background + texts/icons as elements)
    //
    // Never fails the generation: if this step breaks for a side, or the
    // background still shows text after a retry, that side simply stays a
    // flat image, exactly like before.
    // ---------------------------------------------------------------
    final editable = await Future.wait([
      _buildEditableSide(fullBytes: frontBytes, side: 'front'),
      _buildEditableSide(fullBytes: backBytes, side: 'back'),
    ]);

    return GeneratedCard(
      frontImagePath: frontPath,
      backImagePath: backPath,
      frontBackgroundPath: editable[0]?.backgroundPath,
      frontElements: editable[0]?.elements,
      backBackgroundPath: editable[1]?.backgroundPath,
      backElements: editable[1]?.elements,
    );
  }

  /// Takes the FINISHED card image of one side and produces:
  ///  * a text-free background image (saved to a temp file), and
  ///  * the texts/icons as CardElement JSON, placed for the editor canvas.
  /// The work (including the "is the background really clean?" check) is
  /// done by [EditableCardBuilder]. Returns null if the side must stay flat.
  Future<_EditableSide?> _buildEditableSide({
    required Uint8List fullBytes,
    required String side,
  }) async {
    final result = await EditableCardBuilder.build(
      gemini: GeminiCardService(),
      card: fullBytes,
      canvasSize: CardOrientation.landscape.canvasSize,
      label: side,
    );

    if (result == null) {
      debugPrint('AI CARD SERVICE: editable $side not available, flat image');
      return null;
    }

    try {
      final backgroundPath = await _saveToTempFile(
        result.background,
        side: '${side}_bg',
      );

      debugPrint(
        'AI CARD SERVICE: editable $side ready '
            '(elements=${result.elements.length}, bg=$backgroundPath)',
      );

      return _EditableSide(
        backgroundPath: backgroundPath,
        elements: result.elements,
      );
    } catch (e, st) {
      debugPrint('AI CARD SERVICE: saving $side background failed: $e');
      debugPrint('stack: $st');
      return null;
    }
  }

  /// Gemini returns raw image bytes.
  ///
  /// We save front and back separately because the UI expects:
  ///   frontImagePath
  ///   backImagePath
  Future<String> _saveToTempFile(
      Uint8List bytes, {
        required String side,
      }) async {
    final dir = await getTemporaryDirectory();

    final file = File(
      '${dir.path}/ai_card_${side}_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return file.path;
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
      final asset = kReadyTemplateAssets[templateId] ??
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

class _EditableSide {
  final String backgroundPath;
  final List<Map<String, dynamic>> elements;

  const _EditableSide({
    required this.backgroundPath,
    required this.elements,
  });
}