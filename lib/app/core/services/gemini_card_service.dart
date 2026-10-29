import '../utils/ai_usage_log.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../core/translations/tr_extension.dart';

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

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: _region,
  );

  Future<Uint8List> generateCard({
    required String prompt,
    required Uint8List referenceBytes,
    required String referenceMime,
    Uint8List? logoBytes,
    String logoMime = 'image/png',
  }) async {
    debugPrint(
      'GeminiCardService.generateCard: '
      'reference=${referenceBytes.length}B '
      'logo=${logoBytes?.length ?? 0}B prompt=${prompt.length} chars',
    );

    try {
      final callable = _functions.httpsCallable(
        'generateCard',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 180)),
      );

      final result = await callable
          .call(<String, dynamic>{
            'prompt': prompt,
            'referenceBase64': base64Encode(referenceBytes),
            'referenceMime': referenceMime,
            if (logoBytes != null) 'logoBase64': base64Encode(logoBytes),
            if (logoBytes != null) 'logoMime': logoMime,
          })
          .timeout(const Duration(seconds: 190));

      final data = result.data;
      logAiUsage('card image', data is Map ? data['_usage'] : null);
      final b64 = data is Map ? data['imageBase64'] : null;

      if (b64 is! String || b64.isEmpty) {
        throw GeminiException('gemini_error_no_image'.tr);
      }

      final bytes = base64Decode(b64);
      if (bytes.isEmpty) {
        throw GeminiException('gemini_error_empty_card'.tr);
      }

      debugPrint('GeminiCardService.generateCard: got ${bytes.length}B');
      return bytes;
    } on TimeoutException {
      throw GeminiException('gemini_error_timeout'.tr);
    } on GeminiException {
      rethrow;
    } on FirebaseFunctionsException catch (e, stackTrace) {
      debugPrint('generateCard function error: ${e.code} ${e.message}');
      debugPrint('$stackTrace');
      throw GeminiException(_messageForFunctionsError(e));
    } catch (e, stackTrace) {
      debugPrint('generateCard unknown error: $e');
      debugPrint('$stackTrace');
      throw GeminiException('gemini_error_unreachable'.tr);
    }
  }

  String _messageForFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'deadline-exceeded':
        return 'gemini_error_timeout'.tr;
      case 'resource-exhausted':
        return 'gemini_error_busy'.tr;
      case 'unauthenticated':
      case 'permission-denied':
        return 'gemini_error_unverified'.tr;
      case 'invalid-argument':
        return 'gemini_error_rejected'.tr;
      case 'failed-precondition':
        return 'gemini_error_not_set_up'.tr;
      case 'unavailable':
      case 'internal':
        return 'gemini_error_unavailable'.tr;
      default:
        return 'gemini_error_generic'.tr;
    }
  }
}
