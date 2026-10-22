import 'package:get/get.dart';

import '../../paywall/controller/subscription_controller.dart';
import '../service/career_ai_service.dart';
import 'career_fixes.dart';
import 'career_score_store.dart';

export 'career_fixes.dart';

/// State of the profile report: which fixes are done, the score and the
/// AI fix suggestions and the free AI rewrites.
class ProfileReportController extends GetxController {
  ProfileReportController({
    bool? isPro,
    int rewritesLeft = freeRewrites,
    Set<String> done = const {},
    this.persist = false,
  }) : _pinnedPro = isPro,
       rewritesLeft = rewritesLeft.obs,
       // Live reports share the saved state with the hub; pinned ones
       // (previews/tests) keep their own.
       done = persist ? CareerScoreStore.done : {...done}.obs;

  /// Reads and writes the saved score/fixes ([CareerScoreStore]).
  final bool persist;

  @override
  void onInit() {
    super.onInit();
    // A report implies a scan.
    if (persist && !CareerScoreStore.scanned.value) {
      // After the build that created this controller (see CareerScoreStore).
      Future.microtask(CareerScoreStore.newScan);
    }
  }

  static const freeRewrites = 3;
  static const baseScore = 54;

  final bool? _pinnedPro;

  bool get isPro =>
      _pinnedPro ??
      (Get.isRegistered<SubscriptionController>() &&
          Get.find<SubscriptionController>().isUserPro.value);

  final RxSet<String> done;
  final RxInt rewritesLeft;

  /// AI-suggested text per fix (empty until generated; Try another and Edit
  /// change it).
  final suggestion = <String, RxString>{};
  final _history = <String, List<String>>{};

  /// Fixes whose suggestion is being generated right now.
  final loading = <String>{}.obs;

  int get total => kReportFixes.length;
  int get doneCount => done.length;

  int get gained => [
    for (final f in kReportFixes)
      if (done.contains(f.id)) f.points,
  ].fold(0, (a, b) => a + b);

  /// Score of the scan this report shows.
  int get scanScore => persist ? CareerScoreStore.base.value : baseScore;

  /// What the score will be with the accepted fixes ("About 68").
  int get score => scanScore + gained;

  /// The score the ring shows: the scan's, or the confirmed one after a
  /// re-scan.
  int get ringScore => persist ? CareerScoreStore.current : baseScore;

  /// Score if every fix were applied.
  int get potential =>
      scanScore + kReportFixes.fold(0, (a, f) => a + f.points);

  bool isLocked(ReportFix f) => !isPro && !f.free;

  /// Fixes this user can still do.
  List<ReportFix> get todo => [
    for (final f in kReportFixes)
      if (!done.contains(f.id) && !isLocked(f)) f,
  ];

  int get lockedCount => [
    for (final f in kReportFixes)
      if (isLocked(f) && !done.contains(f.id)) f,
  ].length;

  ReportFix? get next => todo.isEmpty ? null : todo.first;

  bool get canRewrite => isPro || rewritesLeft.value > 0;

  RxString textFor(ReportFix f) => suggestion.putIfAbsent(f.id, () => ''.obs);

  /// What the profile has for [f] now: the scan's excerpt, else [fallback].
  String currentFor(ReportFix f, String fallback) {
    final t = persist ? CareerScoreStore.currentText[f.partId] : null;
    return (t == null || t.trim().isEmpty) ? fallback : t;
  }

  /// The profile as scanned, for context.
  String get _profileContext => persist
      ? [
          for (final e in CareerScoreStore.currentText.entries)
            if (e.value.trim().isNotEmpty) '${e.key}: ${e.value}',
        ].join('\n')
      : '';

  Future<void> _generate(ReportFix f, String current, String issue) async {
    if (loading.contains(f.id)) return;
    loading.add(f.id);
    try {
      final text = await CareerAi.instance.fixSuggestion(
        fixId: f.id,
        issue: issue,
        current: current,
        avoid: [...?_history[f.id]],
        profile: _profileContext,
      );
      _history.putIfAbsent(f.id, () => []).add(text);
      textFor(f).value = text;
    } finally {
      loading.remove(f.id);
    }
  }

  /// The first suggestion for [f] (free). Does nothing if it already has one.
  /// Throws if the AI call fails.
  Future<void> loadSuggestion(
    ReportFix f, {
    required String current,
    required String issue,
  }) async {
    if (textFor(f).value.isNotEmpty) return;
    await _generate(f, current, issue);
  }

  /// A different suggestion; uses one free rewrite. False if none are left;
  /// a failed AI call costs nothing and throws.
  Future<bool> tryAnother(
    ReportFix f, {
    required String current,
    required String issue,
  }) async {
    if (!canRewrite) return false;
    await _generate(f, current, issue);
    if (!isPro) rewritesLeft.value--;
    return true;
  }

  void markDone(ReportFix f) {
    if (persist) {
      CareerScoreStore.markDone(f.id);
    } else {
      done.add(f.id);
    }
  }
}
