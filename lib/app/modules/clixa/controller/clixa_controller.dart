import 'dart:math' as math;

import 'package:get/get.dart' hide Trans;

import '../../../core/translations/tr_extension.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../../profile_setup/service/profile_store.dart';
import '../service/clixa_ai_service.dart';
import '../service/clixa_chat_store.dart';
import '../model/clixa_models.dart';

/// Clixa's chats. The replies come from the AI (see [ClixaAi]); the chats and
/// the "free today" counter are saved on the device ([ClixaChatStore]), so they
/// are still there after the app is closed and reopened.
class ClixaController extends GetxController {
  static const freeChatsPerDay = 3;
  static const freeMessagesPerChat = 3;

  static ClixaController get to => Get.isRegistered<ClixaController>()
      ? Get.find<ClixaController>()
      : Get.put(ClixaController(), permanent: true);

  /// Newest first.
  final chats = <ClixaChat>[].obs;
  final chatsStartedToday = 0.obs;

  /// The day [chatsStartedToday] counts for; a new day starts from zero.
  String _countDay = ClixaChatStore.dayKey();

  @override
  void onInit() {
    super.onInit();
    final saved = ClixaChatStore.load();
    chats.assignAll(saved.chats);
    _countDay = saved.day;
    chatsStartedToday.value = saved.startedToday;
  }

  int get _usedToday =>
      _countDay == ClixaChatStore.dayKey() ? chatsStartedToday.value : 0;

  Future<void> _save() =>
      ClixaChatStore.save(chats, _countDay, chatsStartedToday.value);

  bool get isPro =>
      Get.isRegistered<SubscriptionController>() &&
      Get.find<SubscriptionController>().isUserPro.value;

  int get freeChatsLeft => math.max(0, freeChatsPerDay - _usedToday);

  bool get canStartChat => isPro || freeChatsLeft > 0;

  /// Starts a chat. It uses one of today's free chats only once the first
  /// message is answered (see [send]), so opening a chat and leaving costs
  /// nothing. The caller checks [canStartChat].
  ClixaChat startChat(ClixaMode mode) {
    final chat = ClixaChat(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mode: mode,
      title: 'clixa_new_chat_title'.trParams({'mode': mode.titleKey.tr}),
    );
    chat.messages.add(ClixaMessage(fromUser: false, text: mode.openingKey.tr));
    chats.insert(0, chat);
    return chat;
  }

  bool limitReached(ClixaChat chat) =>
      !isPro && chat.userMessages >= freeMessagesPerChat;

  /// A line about the user for Clixa's context.
  String _about() {
    if (!Get.isRegistered<ProfileStore>()) return '';
    final p = ProfileStore.to.profile.value;
    return [
      p.fullName,
      if (p.designation.isNotEmpty && p.companyName.isNotEmpty)
        '${p.designation} at ${p.companyName}'
      else
        p.designation.isNotEmpty ? p.designation : p.companyName,
    ].where((s) => s.trim().isNotEmpty).join(', ');
  }

  /// Adds the user's message and asks Clixa for the answer. Returns false
  /// (and sends nothing) when the free limit is reached. If the AI call
  /// fails, the message is taken back out (it doesn't count) and the error is
  /// rethrown for the screen to show.
  Future<bool> send(ClixaChat chat, String text) async {
    final t = text.trim();
    if (t.isEmpty || limitReached(chat)) return false;

    final oldTitle = chat.title.value;
    final first = chat.userMessages == 0;
    chat.messages.add(ClixaMessage(fromUser: true, text: t));
    if (first) {
      // The chat is named after what it is about.
      chat.title.value = t.length > 30 ? '${t.substring(0, 30).trim()}…' : t;
    }

    chat.thinking.value = true;
    try {
      final r = await ClixaAi.instance.reply(
        mode: chat.mode,
        history: [
          for (final m in chat.messages)
            if (m.verdict == null) (fromUser: m.fromUser, text: m.text),
        ],
        about: _about(),
      );
      if (first) {
        final today = ClixaChatStore.dayKey();
        chatsStartedToday.value =
            (_countDay == today ? chatsStartedToday.value : 0) + 1;
        _countDay = today;
      }
      chat.messages.add(ClixaMessage(fromUser: false, text: r.text));
      if (r.verdict != null) {
        chat.messages.add(ClixaMessage(fromUser: false, verdict: r.verdict));
      }
      return true;
    } catch (_) {
      chat.messages.removeLast(); // the user's message
      if (first) chat.title.value = oldTitle;
      rethrow;
    } finally {
      chat.thinking.value = false;
      await _save();
    }
  }

  void rename(ClixaChat chat, String name) {
    final n = name.trim();
    if (n.isNotEmpty) chat.title.value = n;
    _save();
  }

  void delete(ClixaChat chat) {
    chats.remove(chat);
    _save();
  }

  /// Back to nothing (tests).
  void reset() {
    chats.clear();
    chatsStartedToday.value = 0;
  }
}
