import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../service/career_ai_service.dart';

/// The profile the Profile Builder generated, saved on the device. A free
/// user builds once; after that the hub opens this profile instead of the
/// builder. Edits and rewrites made on the profile page are saved too.
abstract final class GeneratedProfileStore {
  static const _key = 'career_generated_profile';

  /// A profile has been generated.
  static final built = false.obs;

  static ProfileDraftTexts? texts;

  /// Free AI rewrites left on the profile page.
  static int rewritesLeft = 0;

  static bool _loaded = false;

  /// Reads the saved profile once (memory is the truth afterwards).
  static void load() {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = GetStorage().read<Map>(_key);
      if (raw == null) return;
      final m = Map<String, dynamic>.from(raw);
      final h = m['headline'], a = m['about'], e = m['experience'];
      if (h is! String || a is! String || e is! String) return;
      texts = (headline: h, about: a, experience: e);
      rewritesLeft = (m['rewritesLeft'] as num?)?.toInt() ?? 0;
      built.value = true;
    } catch (_) {}
  }

  static void save(ProfileDraftTexts t, int rewrites) {
    _loaded = true;
    texts = t;
    rewritesLeft = rewrites;
    built.value = true;
    try {
      GetStorage().write(_key, {
        'headline': t.headline,
        'about': t.about,
        'experience': t.experience,
        'rewritesLeft': rewrites,
      });
    } catch (_) {}
  }

  /// Back to nothing (tests, sign-out).
  static void clear() {
    _loaded = true;
    texts = null;
    rewritesLeft = 0;
    built.value = false;
    try {
      GetStorage().remove(_key);
    } catch (_) {}
  }
}
