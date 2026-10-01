import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Error with a message that is safe to show to the user.
class GeminiException implements Exception {
  final String message;

  const GeminiException(this.message);

  @override
  String toString() => message;
}

class GeminiCardService {
  static const String _model = 'gemini-3.1-flash-image';

  static const String _layoutModel = 'gemini-2.5-flash';

  Future<Uint8List> generateCard({
    required String prompt,
    required Uint8List referenceBytes,
    required String referenceMime,
  }) async {
    debugPrint('========== FIREBASE AI REQUEST START ==========');
    debugPrint('Model: $_model');
    debugPrint('Reference MIME: $referenceMime');
    debugPrint('Reference bytes: ${referenceBytes.length}');
    debugPrint('Prompt length: ${prompt.length}');
    debugPrint('================================================');

    try {
      /*
       * Firebase AI Logic model.
       *
       * The model is configured to return image output only.
       */
      final model = FirebaseAI.googleAI().generativeModel(
        model: _model,
        generationConfig: GenerationConfig(
          responseModalities: [
            ResponseModalities.image,
          ],
        ),
      );

      /*
       * Send the selected business-card template/reference image
       * together with the prompt.
       */
      final imagePart = InlineDataPart(
        referenceMime,
        referenceBytes,
      );

      final textPart = TextPart(prompt);

      final content = Content.multi([
        imagePart,
        textPart,
      ]);

      debugPrint('Sending image + prompt to Firebase AI Logic...');

      final response = await model
          .generateContent([
        content,
      ])
          .timeout(
        const Duration(seconds: 180),
      );

      debugPrint('========== FIREBASE AI RESPONSE ==========');
      debugPrint(
        'Candidates: ${response.candidates.length}',
      );
      debugPrint(
        'Image parts: ${response.inlineDataParts.length}',
      );
      debugPrint('==========================================');

      /*
       * Gemini image models return the generated image
       * as an InlineDataPart.
       */
      if (response.inlineDataParts.isNotEmpty) {
        final imageBytes =
            response.inlineDataParts.first.bytes;

        if (imageBytes.isEmpty) {
          throw const GeminiException(
            "The AI didn't return a card this time. Please try again.",
          );
        }

        debugPrint(
          '========== GENERATED IMAGE FOUND ==========',
        );
        debugPrint(
          'Generated image bytes: ${imageBytes.length}',
        );
        debugPrint(
          '===========================================',
        );

        return imageBytes;
      }

      /*
       * If Gemini returned text instead of an image,
       * log it for debugging.
       */
      final textResponse = response.text;

      debugPrint(
        'Firebase AI text response: $textResponse',
      );

      throw const GeminiException(
        'The AI did not return a generated card image. Please try again.',
      );
    } on TimeoutException {
      debugPrint(
        '========== FIREBASE AI TIMEOUT ==========',
      );

      throw const GeminiException(
        'The AI took too long to respond. Please try again.',
      );
    } on GeminiException {
      rethrow;
    } on FirebaseAIException catch (e, stackTrace) {
      debugPrint(
        '========== FIREBASE AI ERROR ==========',
      );
      debugPrint('Error: $e');
      debugPrint('Message: ${e.message}');
      debugPrint('Stack: $stackTrace');
      debugPrint('========================================');

      throw GeminiException(
        _messageForFirebaseError(
          e.message,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        '========== FIREBASE AI UNKNOWN ERROR ==========',
      );
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('===============================================');

      throw const GeminiException(
        'Could not reach the AI service. Check your connection and try again.',
      );
    }
  }

  /// Reads a finished card image and returns the raw JSON text describing
  /// every text / icon on it (see AiCardPromptBuilder.buildLayoutPrompt).
  Future<String> generateLayoutJson({
    required String prompt,
    required Uint8List imageBytes,
    required String imageMime,
  }) async {
    debugPrint('========== FIREBASE AI LAYOUT REQUEST ==========');
    debugPrint('Model: $_layoutModel');
    debugPrint('Image bytes: ${imageBytes.length}');
    debugPrint('================================================');

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: _layoutModel,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          responseMimeType: 'application/json',
        ),
      );

      final response = await model
          .generateContent([
        Content.multi([
          InlineDataPart(imageMime, imageBytes),
          TextPart(prompt),
        ]),
      ])
          .timeout(const Duration(seconds: 90));

      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw const GeminiException(
          "The AI didn't return the card layout. Please try again.",
        );
      }

      debugPrint('Layout JSON length: ${text.length}');
      return text;
    } on TimeoutException {
      debugPrint('========== FIREBASE AI LAYOUT TIMEOUT ==========');

      throw const GeminiException(
        'The AI took too long to respond. Please try again.',
      );
    } on GeminiException {
      rethrow;
    } on FirebaseAIException catch (e, stackTrace) {
      debugPrint('========== FIREBASE AI LAYOUT ERROR ==========');
      debugPrint('Message: ${e.message}');
      debugPrint('Stack: $stackTrace');
      debugPrint('==============================================');

      throw GeminiException(_messageForFirebaseError(e.message));
    } catch (e, stackTrace) {
      debugPrint('========== FIREBASE AI LAYOUT UNKNOWN ERROR ==========');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('======================================================');

      throw const GeminiException(
        'Could not reach the AI service. Check your connection and try again.',
      );
    }
  }

  String _messageForFirebaseError(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('has not been used') ||
        lowerMessage.contains('disabled') ||
        lowerMessage.contains('not enabled')) {
      return 'Firebase AI Logic is not enabled for this Firebase project yet. '
          'Enable it in the Firebase console (Build → AI Logic) and try again.';
    }

    if (lowerMessage.contains('quota') ||
        lowerMessage.contains('resource-exhausted') ||
        lowerMessage.contains('billing') ||
        lowerMessage.contains('exceeded')) {
      return 'The Gemini image-generation quota or billing limit has been reached.';
    }

    if (lowerMessage.contains('permission') ||
        lowerMessage.contains('unauthenticated') ||
        lowerMessage.contains('unauthorized')) {
      return 'Firebase AI is not authorized for this app. Check your Firebase AI configuration.';
    }

    if (lowerMessage.contains('invalid')) {
      return 'The AI image request was rejected. Please try again.';
    }

    if (lowerMessage.contains('unavailable') ||
        lowerMessage.contains('internal')) {
      return 'The Gemini AI service is temporarily unavailable. Please try again.';
    }

    return 'Something went wrong while generating the card.';
  }
}