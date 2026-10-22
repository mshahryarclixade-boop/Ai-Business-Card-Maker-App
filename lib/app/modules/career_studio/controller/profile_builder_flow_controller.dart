import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../profile_setup/service/profile_store.dart';

/// The unfinished Profile Builder, saved when the user leaves midway so the
/// Career Studio hub can offer to resume it.
abstract final class ProfileBuilderDraftStore {
  static const _key = 'career_builder_draft';

  /// Whether a draft is saved, and the step it stopped on (for the hub card).
  static final hasDraft = false.obs;
  static final step = 1.obs;

  /// Reads the saved draft's state into the observables (call at startup /
  /// before showing the hub).
  static Map<String, dynamic>? load() {
    try {
      final raw = GetStorage().read<Map>(_key);
      if (raw == null) {
        hasDraft.value = false;
        return null;
      }
      final m = Map<String, dynamic>.from(raw);
      hasDraft.value = true;
      step.value = (m['step'] as num?)?.toInt() ?? 1;
      return m;
    } catch (_) {
      return null;
    }
  }

  static void save(Map<String, dynamic> json) {
    hasDraft.value = true;
    step.value = (json['step'] as num?)?.toInt() ?? 1;
    try {
      GetStorage().write(_key, json);
    } catch (_) {}
  }

  static void clear() {
    hasDraft.value = false;
    try {
      GetStorage().remove(_key);
    } catch (_) {}
  }
}

/// Answers of the Profile Builder steps. Kept in memory so "Your answers
/// are saved" holds when the user leaves and comes back during the session.
class ProfileBuilderFlowController extends GetxController {
  static const maxAudience = 3;

  static const goals = [
    'Get hired',
    'Win clients',
    'Raise funding',
    'Build authority',
  ];
  static const audiences = [
    'Startup founders',
    'Recruiters',
    'Product managers',
    'Agencies',
    'Investors',
    'Small businesses',
  ];
  static const tones = ['Professional', 'Friendly', 'Bold'];

  /// Experience bands (ids; display keys live in the view).
  static const experienceBands = ['0-2', '3-5', '6-10', '10+'];

  final name = TextEditingController();
  final role = TextEditingController();
  final company = TextEditingController();
  final location = TextEditingController();
  final wins = TextEditingController();

  final RxString experience = '3-5'.obs;
  final RxString goal = 'Win clients'.obs;
  final RxSet<String> audience = <String>{
    'Startup founders',
    'Product managers',
  }.obs;
  final RxString tone = 'Professional'.obs;

  final RxInt step = 1.obs;

  @override
  void onInit() {
    super.onInit();
    final draft = ProfileBuilderDraftStore.load();
    if (draft != null) {
      applyDraft(draft);
    } else {
      prefillFromCard();
    }
  }

  Map<String, dynamic> toDraft() => {
    'step': step.value,
    'name': name.text,
    'role': role.text,
    'company': company.text,
    'location': location.text,
    'wins': wins.text,
    'experience': experience.value,
    'goal': goal.value,
    'audience': audience.toList(),
    'tone': tone.value,
  };

  /// The answers as sent to the AI.
  Map<String, dynamic> toAnswers() => {
    'name': name.text.trim(),
    'role': role.text.trim(),
    'company': company.text.trim(),
    'location': location.text.trim(),
    'wins': wins.text.trim(),
    'experience': experience.value,
    'goal': goal.value,
    'audience': audience.toList(),
    'tone': tone.value,
  };

  /// Restores a saved draft (the step is left to the caller).
  void applyDraft(Map<String, dynamic> d) {
    name.text = (d['name'] as String?) ?? '';
    role.text = (d['role'] as String?) ?? '';
    company.text = (d['company'] as String?) ?? '';
    location.text = (d['location'] as String?) ?? '';
    wins.text = (d['wins'] as String?) ?? '';
    experience.value = (d['experience'] as String?) ?? '3-5';
    goal.value = (d['goal'] as String?) ?? 'Win clients';
    final a = d['audience'];
    if (a is List) audience.assignAll(a.whereType<String>());
    tone.value = (d['tone'] as String?) ?? 'Professional';
  }

  /// True once the user has moved past step 1 or changed anything.
  bool get hasProgress {
    final p = Get.isRegistered<ProfileStore>()
        ? ProfileStore.to.profile.value
        : null;
    return step.value > 1 ||
        location.text.trim().isNotEmpty ||
        wins.text.trim().isNotEmpty ||
        name.text.trim() != (p?.fullName.trim() ?? '') ||
        role.text.trim() != (p?.designation.trim() ?? '') ||
        company.text.trim() != (p?.companyName.trim() ?? '') ||
        experience.value != '3-5' ||
        goal.value != 'Win clients' ||
        tone.value != 'Professional' ||
        !(audience.length == 2 &&
            audience.contains('Startup founders') &&
            audience.contains('Product managers'));
  }

  /// Leaving midway keeps the answers as a draft; finishing clears it.
  void saveDraftIfStarted() {
    if (hasProgress) ProfileBuilderDraftStore.save(toDraft());
  }

  /// Name, role and company come from the user's business card.
  void prefillFromCard() {
    if (!Get.isRegistered<ProfileStore>()) return;
    final p = ProfileStore.to.profile.value;
    if (name.text.isEmpty) name.text = p.fullName.trim();
    if (role.text.isEmpty) role.text = p.designation.trim();
    if (company.text.isEmpty) company.text = p.companyName.trim();
  }

  void toggleAudience(String a) {
    if (audience.contains(a)) {
      audience.remove(a);
    } else if (audience.length < maxAudience) {
      audience.add(a);
    }
  }

  void next() {
    if (step.value < 3) step.value++;
  }

  void back() {
    if (step.value > 1) step.value--;
  }

  @override
  void onClose() {
    name.dispose();
    role.dispose();
    company.dispose();
    location.dispose();
    wins.dispose();
    super.onClose();
  }
}
