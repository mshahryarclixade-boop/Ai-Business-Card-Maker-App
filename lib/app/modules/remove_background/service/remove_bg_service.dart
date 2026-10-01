import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class RemoveBgService {
  RemoveBgService({String? apiKey})
      : apiKey = apiKey ??
      const String.fromEnvironment(
        'REMOVE_BG_API_KEY',
        defaultValue: 'API-KEY-HERE',
      );

  final String apiKey;
  static const _endpoint = 'https://api.remove.bg/v1.0/removebg';

  Future<Uint8List> removeBackground(File imageFile) async {
    if (apiKey.isEmpty) {
      throw RemoveBgException(
        'Missing remove.bg API key. Add REMOVE_BG_API_KEY via '
            '--dart-define or pass it to RemoveBgService().',
      );
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint))
        ..headers['X-Api-Key'] = apiKey
        ..fields['size'] = 'auto'
        ..fields['format'] = 'png'
        ..files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      throw RemoveBgException(_messageForStatus(response.statusCode, response.body));
    } on RemoveBgException {
      rethrow;
    } catch (e) {
      throw RemoveBgException('Could not reach remove.bg. Check your connection and try again.');
    }
  }

  String _messageForStatus(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        return 'That image could not be processed. Try a different photo.';
      case 402:
        return 'Background removal credits are exhausted for this API key.';
      case 403:
        return 'Invalid or unauthorized remove.bg API key.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return 'Background removal failed (error $statusCode). Please try again.';
    }
  }
}

class RemoveBgException implements Exception {
  RemoveBgException(this.message);
  final String message;

  @override
  String toString() => message;
}