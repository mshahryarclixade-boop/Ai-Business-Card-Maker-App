import 'package:get_storage/get_storage.dart';

/// The stable address of the user's digital card. It never changes, so a QR
/// printed today keeps working after the details are edited.
class DigitalCardLink {
  DigitalCardLink._();

  /// TODO: replace with your hosted web page address.
  static const String baseUrl = 'https://example.com/c';

  static const String _key = 'digital_card_id';

  static String get id {
    final box = GetStorage();
    var value = box.read<String>(_key);
    if (value == null) {
      final now = DateTime.now().microsecondsSinceEpoch;
      value = now.toRadixString(36);
      box.write(_key, value);
    }
    return value;
  }

  static String get url => '$baseUrl/$id';
}