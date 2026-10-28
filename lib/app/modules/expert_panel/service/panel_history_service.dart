import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../model/expert_models.dart';

/// A saved panel discussion.
class SavedPanel {
  SavedPanel(this.session, this.updatedAt);

  final PanelSession session;
  final DateTime updatedAt;

  String get when => '${updatedAt.day}/${updatedAt.month}';
}

/// Recent panel discussions, stored on the device (newest first).
class PanelHistory {
  PanelHistory._();

  static const _key = 'panel_history';
  static const _max = 20;

  static Future<List<SavedPanel>> load() async {
    try {
      final raw = GetStorage().read<String>(_key);
      if (raw == null) return [];
      final out = <SavedPanel>[];
      for (final j in jsonDecode(raw) as List) {
        try {
          out.add(_fromJson(j));
        } catch (_) {} // skip a damaged entry
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Adds the discussion, or updates it if it was saved before.
  static Future<void> save(PanelSession s) async {
    final first = s.messages.where((m) => m.fromUser).firstOrNull;
    if (first == null) return;
    final title = first.text.length > 40
        ? '${first.text.substring(0, 40)}…'
        : first.text;
    try {
      final box = GetStorage();
      final raw = box.read<String>(_key);
      final list = raw == null ? [] : (jsonDecode(raw) as List);
      list.removeWhere((j) => j['id'] == s.id);
      list.insert(0, {
        'id': s.id,
        'title': title,
        'experts': s.experts,
        'mode': s.mode.id,
        'round': s.round,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'messages': [
          for (final m in s.messages)
            {'speaker': m.speaker, 'text': m.text, 'round': m.round},
        ],
        // The server's workflow state (stage, strikes, notebooks / case file),
        // so a discussion continues exactly where it stopped.
        'engine': s.engine,
      });
      await box.write(_key, jsonEncode(list.take(_max).toList()));
    } catch (_) {}
  }

  static SavedPanel _fromJson(dynamic j) {
    final s = PanelSession(
      id: j['id'],
      experts: [for (final i in j['experts']) i as int],
      mode: PanelMode.values.firstWhere((m) => m.id == j['mode']),
      title: j['title'],
      round: j['round'],
      engine: j['engine'] is Map
          ? Map<String, dynamic>.from(j['engine'] as Map)
          : null,
    );
    s.messages.addAll([
      for (final m in j['messages'])
        PanelMessage(speaker: m['speaker'], text: m['text'], round: m['round']),
    ]);
    return SavedPanel(s, DateTime.fromMillisecondsSinceEpoch(j['updatedAt']));
  }
}
