import 'package:get/get.dart';

import '../../paywall/controller/subscription_controller.dart';
import 'generated_profile_store.dart';

/// Which section of the generated profile.
enum DraftSection { headline, about, experience }

/// The generated profile shown after the builder. "Rewrite" asks the AI for
/// new wording of one section and uses one free rewrite.
class ProfileDraftController extends GetxController {
  ProfileDraftController({
    bool? isPro,
    int rewritesLeft = freeRewrites,
    this.persist = false,
  }) : _pinnedPro = isPro,
       rewritesLeft = rewritesLeft.obs;

  static const freeRewrites = 3;

  /// Save edits and rewrites to [GeneratedProfileStore] (the real profile,
  /// not previews/tests).
  final bool persist;

  final bool? _pinnedPro;

  /// Follows the live subscription unless a state was pinned (tests).
  bool get isPro =>
      _pinnedPro ??
      (Get.isRegistered<SubscriptionController>() &&
          Get.find<SubscriptionController>().isUserPro.value);

  final RxInt rewritesLeft;

  final texts = <DraftSection, RxString>{
    for (final s in DraftSection.values) s: ''.obs,
  };

  /// Sections being rewritten right now.
  final busy = <DraftSection>{}.obs;

  /// Sets the initial texts.
  void load(Map<DraftSection, String> initial) {
    initial.forEach((s, t) => texts[s]!.value = t);
  }

  bool get canRewrite => isPro || rewritesLeft.value > 0;

  /// Rewrites [section] with [ai] (given the current text) and uses one free
  /// rewrite. A failed call changes nothing and costs nothing: the error is
  /// rethrown for the caller to show.
  Future<void> rewrite(
    DraftSection section,
    Future<String> Function(String current) ai,
  ) async {
    if (!canRewrite || busy.contains(section)) return;
    busy.add(section);
    try {
      texts[section]!.value = (await ai(texts[section]!.value)).trim();
      if (!isPro) rewritesLeft.value--;
      _save();
    } finally {
      busy.remove(section);
    }
  }

  void setText(DraftSection section, String text) {
    texts[section]!.value = text.trim();
    _save();
  }

  void _save() {
    if (!persist) return;
    GeneratedProfileStore.save((
      headline: texts[DraftSection.headline]!.value,
      about: texts[DraftSection.about]!.value,
      experience: texts[DraftSection.experience]!.value,
    ), rewritesLeft.value);
  }
}
