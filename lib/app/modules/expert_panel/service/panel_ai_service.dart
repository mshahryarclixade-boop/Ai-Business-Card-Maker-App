import 'package:get/get.dart';

import '../../career_studio/service/career_ai_service.dart';
import '../../profile_setup/service/profile_store.dart';
import '../model/expert_models.dart';

export '../../career_studio/service/career_ai_service.dart'
    show GeminiException;

/// One panel line (or a Clixa safety line) and what happens next.
class PanelTurn {
  const PanelTurn({
    required this.speaker,
    required this.text,
    required this.then,
    required this.state,
    this.userText,
    this.move,
  });

  /// The speaker's id (`clixa` for the host), or null if nothing was said.
  final String? speaker;
  final String text;

  /// `user` (the user's turn), `continue` (call again) or `end` (session over).
  final String then;

  /// The session state to keep and send with the next call.
  final Map<String, dynamic> state;

  /// The user's message as the server stored it (sensitive data redacted).
  final String? userText;
  final String? move;

  bool get hasLine => speaker != null && text.trim().isNotEmpty;
}

/// The Expert panel's brain. Tests swap [instance] for a fake.
abstract class PanelAi {
  static PanelAi instance = CloudPanelAi();

  /// With no messages yet: Clixa's welcome. With the user's message last: the
  /// Safety check, the Director and the first line it picked. After a panel
  /// line: the next line. Call again while [PanelTurn.then] is `continue`.
  Future<PanelTurn> turn(PanelSession session);
}

/// Asks the existing `generateCard` Cloud Function (`panelTurn`). The Gemini
/// key, every prompt, the Safety check, the Director and the session rules all
/// live on the server.
class CloudPanelAi extends PanelAi {
  final CloudCareerAi _api = CloudCareerAi();

  String? get _userName {
    if (!Get.isRegistered<ProfileStore>()) return null;
    final full = ProfileStore.to.profile.value.fullName.trim();
    return full.isEmpty ? null : full.split(' ').first;
  }

  @override
  Future<PanelTurn> turn(PanelSession session) async {
    final r = await _api.call(
      'panelTurn',
      session.toRequest(userName: _userName),
    );
    final speaker = r['speaker'];
    final state = r['state'];
    return PanelTurn(
      speaker: speaker is String ? speaker : null,
      text: r['text'] is String ? r['text'] as String : '',
      then: r['then'] is String ? r['then'] as String : 'user',
      state: state is Map ? Map<String, dynamic>.from(state) : session.engine,
      userText: r['userText'] is String ? r['userText'] as String : null,
      move: r['move'] is String ? r['move'] as String : null,
    );
  }
}
