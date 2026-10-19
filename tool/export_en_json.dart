import 'dart:convert';
import 'dart:io';

import 'package:ai_business_card_maker/app/core/translations/en_strings.dart';

/// Writes assets/lang/english_en.json from the Dart maps:
/// `dart run tool/export_en_json.dart`
void main() {
  final keys = enStrings.keys.toList()..sort();
  final sorted = {for (final k in keys) k: enStrings[k]};
  File('assets/lang/english_en.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
  );
  stdout.writeln('Wrote ${sorted.length} strings');
}
