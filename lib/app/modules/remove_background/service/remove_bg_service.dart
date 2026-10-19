import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../../../core/translations/tr_extension.dart';

class RemoveBgService {
  RemoveBgService({String? apiKey})
      : apiKey = apiKey ??
      const String.fromEnvironment(
        'REMOVE_BG_API_KEY',
        defaultValue: 'JCLz8sKstHV6BQtjHGPoXzD3',
      );

  final String apiKey;
  static const _endpoint = 'https://api.remove.bg/v1.0/removebg';

  Future<Uint8List> removeBackground(File imageFile) async {
    if (apiKey.isEmpty) {
      throw RemoveBgException(
        'remove_bg_error_missing_key'.tr,
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
      throw RemoveBgException('remove_bg_error_unreachable'.tr);
    }
  }

  String _messageForStatus(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        return 'remove_bg_error_bad_image'.tr;
      case 402:
        return 'remove_bg_error_credits'.tr;
      case 403:
        return 'remove_bg_error_unauthorized'.tr;
      case 429:
        return 'remove_bg_error_rate_limited'.tr;
      default:
        return 'remove_bg_error_generic'.trParams({'code': statusCode});
    }
  }
}

class RemoveBgException implements Exception {
  RemoveBgException(this.message);
  final String message;

  @override
  String toString() => message;
}