import 'dart:convert';
import 'dart:developer';

import 'package:get_storage/get_storage.dart';

import '../model/clixa_models.dart';

/// What was stored: the chats (newest first) and how many free chats were
/// started on [day].
class ClixaSaved {
  const ClixaSaved(this.chats, this.day, this.startedToday);

  final List<ClixaChat> chats;
  final String day;
  final int startedToday;
}

/// Keeps Clixa's chats on the device (GetStorage), so they survive leaving the
/// screen, closing the app and restarting it.
class ClixaChatStore {
  ClixaChatStore._();

  static const _chatsKey = 'clixa_chats';
  static const _dailyKey = 'clixa_daily';
  static const _max = 10;

  /// Tests switch this off: they have no storage directory.
  static bool enabled = true;

  /// "2026-10-28": the day the free-chat counter belongs to.
  static String dayKey([DateTime? d]) {
    final n = d ?? DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static ClixaSaved load() {
    if (!enabled) return ClixaSaved(const [], dayKey(), 0);
    final chats = <ClixaChat>[];
    var day = dayKey();
    var started = 0;
    try {
      final box = GetStorage();
      final raw = box.read<String>(_chatsKey);
      if (raw != null) {
        for (final j in jsonDecode(raw) as List) {
          try {
            chats.add(ClixaChat.fromJson(j as Map<String, dynamic>));
          } catch (e) {
            log('skipped a damaged chat: $e', name: 'ClixaChatStore');
          }
        }
      }
      final d = box.read<String>(_dailyKey);
      if (d != null) {
        final m = jsonDecode(d) as Map<String, dynamic>;
        day = m['day'] as String? ?? day;
        started = (m['count'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      log('load failed: $e', name: 'ClixaChatStore');
    }
    log(
      'saved chats: ${chats.length} of $_max (the oldest beyond $_max are '
      'dropped on the next save)',
      name: 'ClixaChatStore',
    );
    return ClixaSaved(chats, day, started);
  }

  /// Writes every chat the user has written in (an untouched chat is not kept).
  static Future<void> save(
    List<ClixaChat> chats,
    String day,
    int startedToday,
  ) async {
    if (!enabled) return;
    try {
      final box = GetStorage();
      final kept = chats.where((c) => c.userMessages > 0).take(_max).toList();
      await box.write(
        _chatsKey,
        jsonEncode([for (final c in kept) c.toJson()]),
      );
      await box.write(
        _dailyKey,
        jsonEncode({'day': day, 'count': startedToday}),
      );
    } catch (e) {
      log('save failed: $e', name: 'ClixaChatStore');
    }
  }
}
