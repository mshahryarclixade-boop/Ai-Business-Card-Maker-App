import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Trans;
import '../../../core/services/connectivity_service.dart';

import '../../../core/services/gemini_card_service.dart' show GeminiException;
import '../../../core/translations/app_strings.dart';
import '../../../core/utils/ai_usage_log.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/services/remote_config_service.dart';
import '../../paywall/services/credits_gate.dart';
import '../../paywall/services/user_credits_manager.dart';
export '../../../core/services/gemini_card_service.dart' show GeminiException;

/// The three generated sections of the Profile Builder.
typedef ProfileDraftTexts = ({
  String headline,
  String about,
  String experience,
});

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

/// Talks to the text AI Cloud Functions (one per feature, see [functionFor]);
/// the key and model stay on the server.
class CloudCareerAi extends CareerAi {
  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  /// The Cloud Function that serves [task]. Each feature has its own, so
  /// it scales and shows up in billing and logs separately.
  static String functionFor(String task) => switch (task) {
    'buildProfile' || 'rewrite' => 'profileBuilder',
    'analyze' || 'fixSuggestion' => 'profileOptimizer',
    'coachReply' => 'businessCoach',
    'panelTurn' || 'panelReport' => 'expertPanel',
    _ => 'generateCard', // any older task still served there
  };

  /// Calls a text task (Career Studio, Clixa, the Expert Panel).
  Future<Map<String, dynamic>> call(
    String task,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    // Needs the network: offline, the No Internet dialog opens and nothing is
    // charged or sent.
    if (Get.isRegistered<ConnectivityService>() &&
        !await Get.find<ConnectivityService>().ensureInternet()) {
      throw GeminiException('no_internet_title'.tr);
    }
    final cost = RemoteConfigService().creditCosts.forTask(task);
    if (!await CreditGate.canUse(cost: cost, source: 'ai_$task')) {
      throw GeminiException('credit_gate_out_of_credits_title'.tr);
    }
    // The server counts this query for this user (ai_usage/{udid}).
    final udid = await UserCreditsManager().udidOrNull();
    try {
      final result = await _functions
          .httpsCallable(
            functionFor(task),
            options: HttpsCallableOptions(timeout: timeout),
          )
          .call(<String, dynamic>{
            'task': task,
            'language': AppStrings.locale.languageCode,
            'udid': ?udid,
            ...data,
          })
          .timeout(timeout + const Duration(seconds: 5));
      final d = result.data;
      if (d is! Map) throw GeminiException('career_ai_error_generic'.tr);
      logAiUsage(task, d['_usage']);
      // Charged only now that the answer arrived (0 unless Remote Config sets
      // a cost for this feature).
      await CreditGate.spend(cost: cost, source: 'ai_$task');
      return Map<String, dynamic>.from(d);
    } on TimeoutException {
      throw GeminiException('gemini_error_timeout'.tr);
    } on GeminiException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('${functionFor(task)}/$task: ${e.code} ${e.message}');
      if (e.code == 'invalid-argument' && e.message == 'Not a profile.') {
        throw GeminiException('career_ai_error_not_profile'.tr);
      }
      throw GeminiException(_messageFor(e.code));
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
    final r = await call('buildProfile', {'answers': answers});
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
    await call('rewrite', {
      'section': section,
      'text': text,
      if (answers != null) 'answers': answers,
    }),
    'text',
  );

  @override
  Future<ProfileAnalysis> analyze(ProfileScanInput input) async {
    final r = await call('analyze', input.toJson());
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
    await call('fixSuggestion', {
      'fixId': fixId,
      'issue': issue,
      'current': current,
      'avoid': avoid,
      'profile': profile,
    }),
    'text',
  );
}
