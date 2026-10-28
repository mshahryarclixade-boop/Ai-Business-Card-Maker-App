import '../../career_studio/service/career_ai_service.dart';
import '../model/clixa_models.dart';

export '../../career_studio/service/career_ai_service.dart'
    show GeminiException;

/// What Clixa said: text, and for Validate chats sometimes a verdict.
class ClixaReply {
  const ClixaReply(this.text, {this.verdict});

  final String text;
  final ClixaVerdict? verdict;
}

/// Clixa's brain. Tests swap [instance] for a fake.
abstract class ClixaAi {
  static ClixaAi instance = CloudClixaAi();

  /// Clixa's answer to the last message of [history] (oldest first).
  /// [about] is a short line about the user (role, company) for context.
  Future<ClixaReply> reply({
    required ClixaMode mode,
    required List<({bool fromUser, String text})> history,
    String about = '',
  });
}

/// Asks the existing `generateCard` Cloud Function (task `coachReply`), so
/// the Gemini key and model stay on the server.
class CloudClixaAi extends ClixaAi {
  final CloudCareerAi _api = CloudCareerAi();

  @override
  Future<ClixaReply> reply({
    required ClixaMode mode,
    required List<({bool fromUser, String text})> history,
    String about = '',
  }) async {
    final r = await _api.call('coachReply', {
      'mode': mode.id,
      'about': about,
      'messages': [
        for (final m in history)
          {'role': m.fromUser ? 'user' : 'coach', 'text': m.text},
      ],
    });
    final text = r['reply'];
    if (text is! String || text.trim().isEmpty) {
      throw const GeminiException('The AI did not answer. Please try again.');
    }
    return ClixaReply(
      text.trim(),
      verdict: ClixaVerdict.fromJson(r['verdict']),
    );
  }
}
