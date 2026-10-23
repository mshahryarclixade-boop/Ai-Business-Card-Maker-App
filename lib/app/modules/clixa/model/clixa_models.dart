import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The ways to start a chat with Clixa. UI only: the replies are placeholders.
enum ClixaMode {
  discuss('discuss', Icons.lightbulb_outline_rounded),
  validate('validate', Icons.check_circle_outline_rounded),
  plan('plan', Icons.description_outlined),
  numbers('numbers', Icons.bar_chart_rounded),
  talk('talk', Icons.chat_bubble_outline_rounded);

  const ClixaMode(this.id, this.icon);

  final String id;
  final IconData icon;

  String get titleKey => 'clixa_mode_${id}_title';
  String get subtitleKey => 'clixa_mode_${id}_subtitle';

  /// Clixa's first message in a chat of this kind.
  String get openingKey => 'clixa_mode_${id}_opening';

  /// A ready-made first answer the user can tap.
  String get suggestionKey => 'clixa_mode_${id}_suggestion';

  /// Placeholder replies, in order (the last repeats). Validate has a longer
  /// script that ends with a verdict card.
  List<String> get replyKeys => this == ClixaMode.validate
      ? const [
          'clixa_reply_validate_1',
          'clixa_reply_validate_2',
          'clixa_reply_validate_3',
          'clixa_reply_validate_4',
        ]
      : const [
          'clixa_reply_generic_1',
          'clixa_reply_generic_2',
          'clixa_reply_generic_3',
        ];
}

class ClixaMessage {
  const ClixaMessage({
    required this.fromUser,
    this.text = '',
    this.verdict = false,
  });

  final bool fromUser;
  final String text;

  /// An "Idea verdict" card instead of a text bubble (placeholder content).
  final bool verdict;
}

class ClixaChat {
  ClixaChat({required this.id, required this.mode, required String title})
    : title = title.obs;

  final String id;
  final ClixaMode mode;
  final RxString title;
  final messages = <ClixaMessage>[].obs;

  /// Clixa is "typing" a reply.
  final thinking = false.obs;

  int get userMessages => messages.where((m) => m.fromUser).length;
}
