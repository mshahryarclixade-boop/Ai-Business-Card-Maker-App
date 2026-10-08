import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Error with a message that is safe to show to the user.
class GeminiException implements Exception {
  final String message;

  const GeminiException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Gemini model through Firebase Cloud Functions.
/// The API key and model live on the server only.
class GeminiCardService {
  static const String _region = 'us-central1';

  final FirebaseFunctions _functions =
  FirebaseFunctions.instanceFor(region: _region);

  Future<Uint8List> generateCard({
    required String prompt,
    required Uint8List referenceBytes,
    required String referenceMime,
    Uint8List? logoBytes,
    String logoMime = 'image/png',
  }) async {
    debugPrint('GeminiCardService.generateCard: '
        'reference=${referenceBytes.length}B '
        'logo=${logoBytes?.length ?? 0}B prompt=${prompt.length} chars');

    try {
      final callable = _functions.httpsCallable(
        'generateCard',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 180)),
      );

      final result = await callable.call(<String, dynamic>{
        'prompt': prompt,
        'referenceBase64': base64Encode(referenceBytes),
        'referenceMime': referenceMime,
        if (logoBytes != null) 'logoBase64': base64Encode(logoBytes),
        if (logoBytes != null) 'logoMime': logoMime,
      }).timeout(const Duration(seconds: 190));

      final data = result.data;
      final b64 = data is Map ? data['imageBase64'] : null;

      if (b64 is! String || b64.isEmpty) {
        throw const GeminiException(
          'The AI did not return a generated card image. Please try again.',
        );
      }

      final bytes = base64Decode(b64);
      if (bytes.isEmpty) {
        throw const GeminiException(
          "The AI didn't return a card this time. Please try again.",
        );
      }

      debugPrint('GeminiCardService.generateCard: got ${bytes.length}B');
      return bytes;
    } on TimeoutException {
      throw const GeminiException(
        'The AI took too long to respond. Please try again.',
      );
    } on GeminiException {
      rethrow;
    } on FirebaseFunctionsException catch (e, stackTrace) {
      debugPrint('generateCard function error: ${e.code} ${e.message}');
      debugPrint('$stackTrace');
      throw GeminiException(_messageForFunctionsError(e));
    } catch (e, stackTrace) {
      debugPrint('generateCard unknown error: $e');
      debugPrint('$stackTrace');
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
    debugPrint('GeminiCardService.generateLayoutJson: '
        'image=${imageBytes.length}B prompt=${prompt.length} chars');

    try {
      final callable = _functions.httpsCallable(
        'generateLayoutJson',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );

      final result = await callable.call(<String, dynamic>{
        'prompt': prompt,
        'imageBase64': base64Encode(imageBytes),
        'imageMime': imageMime,
      }).timeout(const Duration(seconds: 130));

      final data = result.data;
      final text = data is Map ? data['json'] : null;

      if (text is! String || text.trim().isEmpty) {
        throw const GeminiException(
          "The AI didn't return the card layout. Please try again.",
        );
      }

      debugPrint('Layout JSON length: ${text.length}');
      return text;
    } on TimeoutException {
      throw const GeminiException(
        'The AI took too long to respond. Please try again.',
      );
    } on GeminiException {
      rethrow;
    } on FirebaseFunctionsException catch (e, stackTrace) {
      debugPrint('generateLayoutJson function error: ${e.code} ${e.message}');
      debugPrint('$stackTrace');
      throw GeminiException(_messageForFunctionsError(e));
    } catch (e, stackTrace) {
      debugPrint('generateLayoutJson unknown error: $e');
      debugPrint('$stackTrace');
      throw const GeminiException(
        'Could not reach the AI service. Check your connection and try again.',
      );
    }
  }

  String _messageForFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'deadline-exceeded':
        return 'The AI took too long to respond. Please try again.';
      case 'resource-exhausted':
        return 'The AI service is busy or its limit has been reached. '
            'Please try again later.';
      case 'unauthenticated':
      case 'permission-denied':
        return 'The AI service could not verify this app. Please try again.';
      case 'invalid-argument':
        return 'The AI image request was rejected. Please try again.';
      case 'failed-precondition':
        return 'The AI service is not set up yet. Please try again later.';
      case 'unavailable':
      case 'internal':
        return 'The AI service is temporarily unavailable. Please try again.';
      default:
        return 'Something went wrong while generating the card.';
    }
  }
}