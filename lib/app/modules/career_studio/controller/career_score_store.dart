import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'career_fixes.dart';
import '../service/career_ai_service.dart';

/// The user's profile score and what they've done about it, saved on the
/// device so the Career Studio hub and the report always agree. The scan comes
/// from the AI analysis; without one the score is [firstScan].
abstract final class CareerScoreStore {
  static const _key = 'career_score';

  /// Score of a fresh scan (dummy until there is real analysis).
  static const firstScan = 54;

  /// A report exists (the free scan has been used).
  static final scanned = false.obs;

  /// Score when the profile was scanned.
  static final base = 0.obs;

  /// Strength of each profile part (0-100) from the last scan; empty when the
  /// scan had no breakdown.
  static final partScores = <String, int>{}.obs;

  /// Short excerpt of what the profile has for each part, from the last scan.
  static final currentText = <String, String>{}.obs;

  /// Strength a part reaches once its fix is accepted.
  static const fixedPartScore = 90;

  /// Breakdown score of [partId], counting accepted fixes.
  static int partScore(String partId) {
    final s = partScores[partId] ?? 0;
    final fixed = kReportFixes.any(
      (f) => f.partId == partId && done.contains(f.id),
    );
    return fixed && s < fixedPartScore ? fixedPartScore : s;
  }

  /// Fixes the user accepted ("Use this") since that scan.
  static final done = <String>{}.obs;

  /// The accepted fixes were reviewed and saved; waiting for a re-scan.
  static final fixesReady = false.obs;

  /// A re-scan confirmed the new score.
  static final rescanned = false.obs;

  /// Score before the re-scan.
  static final before = 0.obs;

  static int get gained => [
    for (final f in kReportFixes)
      if (done.contains(f.id)) f.points,
  ].fold(0, (a, b) => a + b);

  /// What the score will be once the accepted fixes are applied.
  static int get expected => (base.value + gained).clamp(0, 100);

  /// The score to show: the scan's own until a re-scan confirms the new one.
  static int get current => rescanned.value ? expected : base.value;

  static bool _loaded = false;

  /// Reads the saved state once (later calls do nothing: memory is the truth,
  /// and changing observables while a screen is building would throw).
  static void load() {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = GetStorage().read<Map>(_key);
      if (raw == null) return;
      final m = Map<String, dynamic>.from(raw);
      scanned.value = m['scanned'] == true;
      base.value = (m['base'] as num?)?.toInt() ?? 0;
      before.value = (m['before'] as num?)?.toInt() ?? 0;
      fixesReady.value = m['fixesReady'] == true;
      rescanned.value = m['rescanned'] == true;
      final ids = [
        ...((m['done'] as List?) ?? const []).whereType<String>(),
      ];
      done
        ..clear()
        ..addAll(ids);
      partScores
        ..clear()
        ..addAll({
          for (final e in ((m['parts'] as Map?) ?? const {}).entries)
            '${e.key}': (e.value as num?)?.toInt() ?? 0,
        });
      currentText
        ..clear()
        ..addAll({
          for (final e in ((m['texts'] as Map?) ?? const {}).entries)
            '${e.key}': '${e.value}',
        });
    } catch (_) {}
  }

  static void _save() {
    try {
      GetStorage().write(_key, {
        'scanned': scanned.value,
        'base': base.value,
        'before': before.value,
        'fixesReady': fixesReady.value,
        'rescanned': rescanned.value,
        'done': done.toList(),
        'parts': Map<String, int>.from(partScores),
        'texts': Map<String, String>.from(currentText),
      });
    } catch (_) {}
  }

  /// Overall score of an analysis: the average of its parts.
  static int scoreOf(ProfileAnalysis a) {
    if (a.scores.isEmpty) return firstScan;
    final sum = a.scores.values.fold(0, (x, y) => x + y);
    return (sum / a.scores.length).round().clamp(0, 100);
  }

  /// A new scan starts the report over. [analysis] (the AI result) sets the
  /// score and breakdown; without one the placeholder score is used.
  static void newScan([ProfileAnalysis? analysis]) {
    final score = analysis == null ? firstScan : scoreOf(analysis);
    scanned.value = true;
    base.value = score;
    before.value = score;
    partScores
      ..clear()
      ..addAll(analysis?.scores ?? const {});
    currentText
      ..clear()
      ..addAll(analysis?.current ?? const {});
    done.clear();
    fixesReady.value = false;
    rescanned.value = false;
    _save();
  }

  static void markDone(String id) {
    done.add(id);
    // Changing the fixes means they have to be reviewed again.
    fixesReady.value = false;
    _save();
  }

  /// Free users: the fixes are saved and a re-scan is due when the free
  /// scan renews.
  static void saveFixes() {
    fixesReady.value = true;
    _save();
  }

  /// Pro re-scan finished: the expected score is now the real one.
  static void completeRescan() {
    before.value = base.value;
    rescanned.value = true;
    fixesReady.value = true;
    _save();
  }

  /// Back to nothing (tests, sign-out).
  static void clear() {
    _loaded = true;
    scanned.value = false;
    base.value = 0;
    before.value = 0;
    done.clear();
    partScores.clear();
    currentText.clear();
    fixesReady.value = false;
    rescanned.value = false;
    try {
      GetStorage().remove(_key);
    } catch (_) {}
  }
}
