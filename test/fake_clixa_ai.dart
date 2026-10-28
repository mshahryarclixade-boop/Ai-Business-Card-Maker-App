import 'package:ai_business_card_maker/app/modules/clixa/model/clixa_models.dart';
import 'package:ai_business_card_maker/app/modules/clixa/service/clixa_ai_service.dart';

/// Offline stand-in for Clixa's AI: recognisable replies, and a verdict on
/// the fourth answer of a Validate chat. Records what it was asked.
class FakeClixaAi extends ClixaAi {
  /// Set to make the next calls fail.
  Object? error;

  final calls = <({ClixaMode mode, List<String> history, String about})>[];

  @override
  Future<ClixaReply> reply({
    required ClixaMode mode,
    required List<({bool fromUser, String text})> history,
    String about = '',
  }) async {
    calls.add((
      mode: mode,
      history: [
        for (final m in history) '${m.fromUser ? 'user' : 'coach'}: ${m.text}',
      ],
      about: about,
    ));
    if (error != null) throw error!;
    final turns = history.where((m) => m.fromUser).length;
    final last = history.last.text;
    if (mode == ClixaMode.validate && turns == 4) {
      return const ClixaReply(
        'Thanks, that is enough for an honest verdict.',
        verdict: ClixaVerdict(
          badge: 'Promising',
          headline: 'Real demand and a healthy margin.',
          strengths: ['Clear buyer', 'Good margin'],
          risks: ['Your time is the limit'],
          next: ['Take 10 pre-orders'],
        ),
      );
    }
    return ClixaReply('Reply $turns to: $last');
  }
}
