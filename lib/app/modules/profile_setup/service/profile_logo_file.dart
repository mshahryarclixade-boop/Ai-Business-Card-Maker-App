import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import 'profile_store.dart';

/// The profile's company logo as a file (cards reference images by path) and
/// its width / height ratio (so a logo is never stretched into its slot).
class ProfileLogoFile {
  const ProfileLogoFile(this.file, this.aspect);

  final File file;
  final double aspect;

  /// null when the profile has no logo. The file is named after the logo's
  /// content and lives in the documents folder, so a card saved with it keeps
  /// working, and a changed logo never replaces the one an old card uses.
  static Future<ProfileLogoFile?> current() async {
    final p = ProfileStore.to.profile.value;
    if (!p.hasLogo) return null;
    return fromBytes(p.logoBytes!);
  }

  static Future<ProfileLogoFile?> fromBytes(Uint8List bytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_logo_${_hash(bytes)}.png');
      if (!await file.exists()) await file.writeAsBytes(bytes, flush: true);
      return ProfileLogoFile(file, await _aspect(bytes));
    } catch (_) {
      return null;
    }
  }

  static Future<double> _aspect(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final ratio = frame.image.width / frame.image.height;
    frame.image.dispose();
    codec.dispose();
    return ratio <= 0 ? 1 : ratio;
  }

  /// FNV-1a over the bytes: the same logo always gets the same file name.
  static String _hash(Uint8List bytes) {
    var h = 0x811c9dc5;
    for (final b in bytes) {
      h = ((h ^ b) * 0x01000193) & 0xffffffff;
    }
    return '${h.toRadixString(16)}_${bytes.length}';
  }
}
