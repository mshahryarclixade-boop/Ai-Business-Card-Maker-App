import 'package:get/get.dart';

import '../model/expert_models.dart';
import '../service/panel_ai_service.dart';
import '../service/panel_history_service.dart';

/// Runs one panel conversation. The server decides everything (the Safety
/// check, who speaks, when the session ends); this controller sends the messages, applies
/// each reply to the session and calls again while the server says `continue`.
class PanelChatController extends GetxController {
  PanelChatController(this.session);

  final PanelSession session;

  /// The panel is working on an answer.
  final thinking = false.obs;

  /// Set once the server ended the session (completed, conduct...).
  late final over = session.isOver.obs;

  /// Safety valve for the loop: a gap is never longer than this many lines.
  static const _maxLinesPerCall = 10;

  /// Clixa's welcome, for a brand-new session.
  Future<void> start() async {
    if (session.messages.isNotEmpty || thinking.value) return;
    thinking.value = true;
    try {
      final t = await PanelAi.instance.turn(session);
      _apply(t);
    } finally {
      thinking.value = false;
    }
  }

  /// Sends [text]. Returns false (and sends nothing) for an empty message or
  /// while the panel is answering. If nothing could be answered, the message is
  /// taken back out and the error is rethrown for the screen to show.
  Future<bool> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || thinking.value || over.value) return false;
    final msg = PanelMessage(text: t, round: session.round);
    session.messages.add(msg);
    thinking.value = true;
    var lines = 0;
    try {
      await _loop(onLine: () => lines++);
      return true;
    } catch (e) {
      if (lines == 0) {
        session.messages.remove(msg);
        rethrow;
      }
      return true; // some lines arrived: keep the conversation, skip the rest
    } finally {
      thinking.value = false;
      await PanelHistory.save(session);
    }
  }

  /// The End button. The session never ends by itself on "thanks" or "bye":
  /// the user asks to end it, Clixa asks "Do you want me to end the session
  /// now?", and only a yes ends it. So this just says it in the chat.
  Future<bool> requestEnd() => send('I want to end the session.');

  Future<void> _loop({void Function()? onLine}) async {
    for (var i = 0; i < _maxLinesPerCall; i++) {
      final t = await PanelAi.instance.turn(session);
      _apply(t);
      if (t.hasLine) onLine?.call();
      if (t.then != 'continue') return;
    }
  }

  void _apply(PanelTurn t) {
    session.engine = t.state;
    // The server may have redacted the user's last message.
    if (t.userText != null) {
      final i = session.messages.lastIndexWhere((m) => m.fromUser);
      if (i >= 0 && session.messages[i].text != t.userText) {
        session.messages[i] = PanelMessage(
          text: t.userText!,
          round: session.messages[i].round,
        );
      }
    }
    if (t.hasLine) {
      session.messages.add(
        PanelMessage(speaker: t.speaker, text: t.text, round: session.round),
      );
    }
    if (session.isOver) over.value = true;
  }
}
