import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/gemini_card_service.dart' show GeminiException;
import '../../../core/translations/app_strings.dart';
import '../../../core/translations/tr_extension.dart';

export '../../../core/services/gemini_card_service.dart' show GeminiException;

/// The three generated sections of the Profile Builder.
typedef ProfileDraftTexts = ({String headline, String about, String experience});

/// A scanned profile: strength 0-100 per part and a short excerpt of what the
/// profile has there. Part ids: headline, about, experience, skills, photo,
/// featured, link.
typedef ProfileAnalysis = ({
  Map<String, int> scores,
  Map<String, String> current,
});

/// What the optimizer scans: pasted text and/or files (already base64).
class ProfileScanInput {
  const ProfileScanInput({this.text = '', this.images = const [], this.pdf});

  final String text;
  final List<({String base64, String mime})> images;
  final String? pdf;

  Map<String, dynamic> toJson() => {
    'text': text,
    if (pdf != null) 'pdf': {'base64': pdf},
    'images': [
      for (final i in images) {'base64': i.base64, 'mime': i.mime},
    ],
  };
}

/// Career Studio's text AI. Tests swap [instance] for a fake.
abstract class CareerAi {
  static CareerAi instance = CloudCareerAi();

  Future<ProfileDraftTexts> buildProfile(Map<String, dynamic> answers);

  /// Same facts, new wording. [section] is headline / about / experience.
  Future<String> rewrite({
    required String section,
    required String text,
    Map<String, dynamic>? answers,
  });

  Future<ProfileAnalysis> analyze(ProfileScanInput input);

  /// Improved text for one report issue.
  Future<String> fixSuggestion({
    required String fixId,
    required String issue,
    required String current,
    List<String> avoid = const [],
    String profile = '',
  });
}

/// Talks to the existing `generateCard` Cloud Function (a request with a
/// `task` is a text task); the key and model stay on the server.
class CloudCareerAi extends CareerAi {
  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<Map<String, dynamic>> _call(
    String task,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(
            'generateCard',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 90),
            ),
          )
          .call(<String, dynamic>{
            'task': task,
            'language': AppStrings.locale.languageCode,
            ...data,
          })
          .timeout(const Duration(seconds: 95));
      final d = result.data;
      if (d is! Map) throw GeminiException('career_ai_error_generic'.tr);
      return Map<String, dynamic>.from(d);
    } on TimeoutException {
      throw GeminiException('gemini_error_timeout'.tr);
    } on GeminiException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('generateCard/$task: ${e.code} ${e.message}');
      throw GeminiException(_messageFor(e.code));
    } catch (e) {
      debugPrint('generateCard/$task: $e');
      throw GeminiException('gemini_error_unreachable'.tr);
    }
  }

  static String _messageFor(String code) => switch (code) {
    'deadline-exceeded' => 'gemini_error_timeout'.tr,
    'resource-exhausted' => 'gemini_error_busy'.tr,
    'unauthenticated' || 'permission-denied' => 'gemini_error_unverified'.tr,
    'invalid-argument' => 'career_ai_error_rejected'.tr,
    'failed-precondition' => 'gemini_error_not_set_up'.tr,
    'unavailable' || 'internal' => 'gemini_error_unavailable'.tr,
    _ => 'career_ai_error_generic'.tr,
  };

  String _str(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v is! String || v.trim().isEmpty) {
      throw GeminiException('career_ai_error_generic'.tr);
    }
    return v.trim();
  }

  @override
  Future<ProfileDraftTexts> buildProfile(Map<String, dynamic> answers) async {
    final r = await _call('buildProfile', {'answers': answers});
    return (
      headline: _str(r, 'headline'),
      about: _str(r, 'about'),
      experience: _str(r, 'experience'),
    );
  }

  @override
  Future<String> rewrite({
    required String section,
    required String text,
    Map<String, dynamic>? answers,
  }) async => _str(
    await _call('rewrite', {
      'section': section,
      'text': text,
      if (answers != null) 'answers': answers,
    }),
    'text',
  );

  @override
  Future<ProfileAnalysis> analyze(ProfileScanInput input) async {
    final r = await _call('analyze', input.toJson());
    final scores = r['scores'];
    final current = r['current'];
    if (scores is! Map) throw GeminiException('career_ai_error_generic'.tr);
    return (
      scores: {
        for (final e in scores.entries)
          '${e.key}': ((e.value as num?)?.toInt() ?? 0).clamp(0, 100),
      },
      current: {
        if (current is Map)
          for (final e in current.entries) '${e.key}': '${e.value ?? ''}',
      },
    );
  }

  @override
  Future<String> fixSuggestion({
    required String fixId,
    required String issue,
    required String current,
    List<String> avoid = const [],
    String profile = '',
  }) async => _str(
    await _call('fixSuggestion', {
      'fixId': fixId,
      'issue': issue,
      'current': current,
      'avoid': avoid,
      'profile': profile,
    }),
    'text',
  );
}
