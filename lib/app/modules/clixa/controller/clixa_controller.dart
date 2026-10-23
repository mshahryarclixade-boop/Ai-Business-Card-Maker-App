import 'dart:math' as math;

import 'package:get/get.dart' hide Trans;

import '../../../core/translations/tr_extension.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../model/clixa_models.dart';

/// Clixa's chats for this session. UI only: nothing is sent anywhere, the
/// replies are scripted placeholders and the "free today" counters live in
/// memory.
class ClixaController extends GetxController {
  static const freeChatsPerDay = 3;
  static const freeMessagesPerChat = 10;

  static ClixaController get to => Get.isRegistered<ClixaController>()
      ? Get.find<ClixaController>()
      : Get.put(ClixaController(), permanent: true);

  /// Newest first.
  final chats = <ClixaChat>[].obs;
  final chatsStartedToday = 0.obs;

  /// Delay before a placeholder reply (shortened in tests).
  Duration replyDelay = const Duration(milliseconds: 700);

  bool get isPro =>
      Get.isRegistered<SubscriptionController>() &&
      Get.find<SubscriptionController>().isUserPro.value;

  int get freeChatsLeft =>
      math.max(0, freeChatsPerDay - chatsStartedToday.value);

  bool get canStartChat => isPro || freeChatsLeft > 0;

  /// Starts a chat (uses one free chat). The caller checks [canStartChat].
  ClixaChat startChat(ClixaMode mode) {
    final chat = ClixaChat(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mode: mode,
      title: 'clixa_new_chat_title'.trParams({'mode': mode.titleKey.tr}),
    );
    chat.messages.add(ClixaMessage(fromUser: false, text: mode.openingKey.tr));
    chats.insert(0, chat);
    chatsStartedToday.value++;
    return chat;
  }

  bool limitReached(ClixaChat chat) =>
      !isPro && chat.userMessages >= freeMessagesPerChat;

  /// Adds the user's message and, after a moment, a placeholder reply.
  /// Returns false (and sends nothing) when the free limit is reached.
  Future<bool> send(ClixaChat chat, String text) async {
    final t = text.trim();
    if (t.isEmpty || limitReached(chat)) return false;

    chat.messages.add(ClixaMessage(fromUser: true, text: t));
    if (chat.userMessages == 1) {
      // The chat is named after what it is about.
      chat.title.value = t.length > 30 ? '${t.substring(0, 30).trim()}…' : t;
    }

    chat.thinking.value = true;
    await Future<void>.delayed(replyDelay);
    final n = chat.userMessages;
    final keys = chat.mode.replyKeys;
    chat.messages.add(
      ClixaMessage(
        fromUser: false,
        text: keys[math.min(n - 1, keys.length - 1)].tr,
      ),
    );
    // Validate ends with an "Idea verdict" once it has the four answers.
    if (chat.mode == ClixaMode.validate && n == keys.length) {
      chat.messages.add(const ClixaMessage(fromUser: false, verdict: true));
    }
    chat.thinking.value = false;
    return true;
  }

  void rename(ClixaChat chat, String name) {
    final n = name.trim();
    if (n.isNotEmpty) chat.title.value = n;
  }

  void delete(ClixaChat chat) => chats.remove(chat);

  /// Back to nothing (tests).
  void reset() {
    chats.clear();
    chatsStartedToday.value = 0;
  }
}
