import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show FontLoader;

/// The app's font (SFPro) isn't bundled in tests: Roboto stands in, so the
/// paywall's text is measured like a real font instead of the wide test font.
Future<void> loadRobotoAsSfPro() async {
  final sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk == null) return;
  final loader = FontLoader('SFPro');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    final file = File('$sdk/bin/cache/artifacts/material_fonts/$f');
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
  }
  await loader.load();
}
