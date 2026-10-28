import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/translations/tr_extension.dart';

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
}

/// The "Idea verdict" Clixa gives at the end of a Validate chat.
class ClixaVerdict {
  const ClixaVerdict({
    required this.badge,
    required this.headline,
    this.strengths = const [],
    this.risks = const [],
    this.next = const [],
  });

  final String badge;
  final String headline;
  final List<String> strengths;
  final List<String> risks;
  final List<String> next;

  /// The verdict as plain text (copy, share, read aloud).
  String get plainText {
    String block(String title, List<String> items) =>
        items.isEmpty ? '' : '\n$title\n${items.map((i) => '- $i').join('\n')}';
    return [
      if (badge.isNotEmpty) badge,
      headline,
      block('clixa_verdict_strengths'.tr, strengths),
      block('clixa_verdict_risks'.tr, risks),
      block('clixa_verdict_next'.tr, next),
    ].where((s) => s.isNotEmpty).join('\n').trim();
  }

  Map<String, dynamic> toJson() => {
    'badge': badge,
    'headline': headline,
    'strengths': strengths,
    'risks': risks,
    'next': next,
  };

  /// Null if [json] isn't a usable verdict.
  static ClixaVerdict? fromJson(dynamic json) {
    if (json is! Map) return null;
    List<String> list(dynamic v) => [
      if (v is List)
        for (final x in v)
          if (x is String && x.trim().isNotEmpty) x.trim(),
    ];
    final headline = json['headline'];
    if (headline is! String || headline.trim().isEmpty) return null;
    final badge = json['badge'];
    return ClixaVerdict(
      badge: badge is String && badge.trim().isNotEmpty ? badge.trim() : '',
      headline: headline.trim(),
      strengths: list(json['strengths']),
      risks: list(json['risks']),
      next: list(json['next']),
    );
  }
}

class ClixaMessage {
  const ClixaMessage({required this.fromUser, this.text = '', this.verdict});

  final bool fromUser;
  final String text;

  /// An "Idea verdict" card instead of a text bubble.
  final ClixaVerdict? verdict;

  Map<String, dynamic> toJson() => {
    'user': fromUser,
    'text': text,
    if (verdict != null) 'verdict': verdict!.toJson(),
  };

  factory ClixaMessage.fromJson(Map<String, dynamic> j) => ClixaMessage(
    fromUser: j['user'] == true,
    text: j['text'] as String? ?? '',
    verdict: ClixaVerdict.fromJson(j['verdict']),
  );
}

class ClixaChat {
  ClixaChat({
    required this.id,
    required this.mode,
    required String title,
    DateTime? createdAt,
  }) : title = title.obs,
       createdAt = createdAt ?? DateTime.now();

  final String id;
  final ClixaMode mode;
  final RxString title;
  final messages = <ClixaMessage>[].obs;
  final DateTime createdAt;

  /// "Today", "Yesterday" or the date.
  String get whenLabel {
    final now = DateTime.now();
    final d = createdAt;
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days <= 0) return 'clixa_today'.tr;
    if (days == 1) return 'clixa_yesterday'.tr;
    return '${d.day}/${d.month}/${d.year}';
  }

  /// The badge of the idea verdict in this chat (e.g. "Promising"), if any.
  String? get verdictBadge {
    for (final m in messages.reversed) {
      final b = m.verdict?.badge;
      if (b != null && b.isNotEmpty) return b;
    }
    return null;
  }

  /// Clixa is "typing" a reply.
  final thinking = false.obs;

  int get userMessages => messages.where((m) => m.fromUser).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mode': mode.id,
    'title': title.value,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'messages': [for (final m in messages) m.toJson()],
  };

  factory ClixaChat.fromJson(Map<String, dynamic> j) {
    final chat = ClixaChat(
      id: j['id'] as String,
      mode: ClixaMode.values.firstWhere((m) => m.id == j['mode']),
      title: j['title'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (j['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
    chat.messages.addAll([
      for (final m in (j['messages'] as List? ?? const []))
        ClixaMessage.fromJson(Map<String, dynamic>.from(m as Map)),
    ]);
    return chat;
  }
}
