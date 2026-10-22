import 'package:ai_business_card_maker/app/modules/career_studio/service/career_ai_service.dart';

/// Offline stand-in for the Career Studio AI: fixed, recognisable answers.
class FakeCareerAi extends CareerAi {
  /// Numbers the generated texts; reset it in setUp.
  int calls = 0;

  /// Set to make the next calls fail.
  Object? error;

  /// Scores returned by [analyze] (they average 54).
  Map<String, int> scores = const {
    'headline': 50,
    'about': 50,
    'experience': 80,
    'skills': 65,
    'photo': 60,
    'featured': 23,
    'link': 50,
  };

  void _maybeFail() {
    if (error != null) throw error!;
  }

  @override
  Future<ProfileDraftTexts> buildProfile(Map<String, dynamic> answers) async {
    _maybeFail();
    final role = answers['role'] ?? '';
    return (
      headline: 'AI headline for $role',
      about: 'AI about text',
      experience: 'AI experience text',
    );
  }

  @override
  Future<String> rewrite({
    required String section,
    required String text,
    Map<String, dynamic>? answers,
  }) async {
    _maybeFail();
    return 'Rewritten $section ${++calls}: $text';
  }

  @override
  Future<ProfileAnalysis> analyze(ProfileScanInput input) async {
    _maybeFail();
    return (
      scores: scores,
      current: {for (final k in scores.keys) k: 'Current $k'},
    );
  }

  @override
  Future<String> fixSuggestion({
    required String fixId,
    required String issue,
    required String current,
    List<String> avoid = const [],
    String profile = '',
  }) async {
    _maybeFail();
    return 'AI suggestion ${++calls} for $fixId';
  }
}
