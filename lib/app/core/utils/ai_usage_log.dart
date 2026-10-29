import 'package:flutter/foundation.dart';

/// Debug-console cost tracking for every AI response. The server measures each
/// model call and adds a `_usage` summary (with a per-response `breakdown`) to
/// its reply; every AI feature (card images, Career Studio, Clixa, Expert Panel
/// turns and reports) reaches the app through a path that calls [logAiUsage].
///
/// The cost is an estimate from assumed prices (see functions/usage.js).
double _sessionCost = 0;
int _sessionTokens = 0;

void logAiUsage(String what, Object? usage) {
  if (!kDebugMode || usage is! Map) return;
  String money(Object? v) => v is num ? '\$${v.toStringAsFixed(6)}' : '?';
  final rows = usage['breakdown'];
  if (rows is List) {
    for (final r in rows.whereType<Map>()) {
      debugPrint(
        'AI_RESPONSE $what/${r['label']}: model=${r['model']} '
        'in=${r['promptTokens']} out=${r['outputTokens']} '
        'total=${r['totalTokens']} cost=${money(r['estimatedCostUsd'])} '
        '(${r['ms']} ms)',
      );
    }
  }
  final cost = usage['estimatedCostUsd'];
  final tokens = usage['totalTokens'];
  if (cost is num) _sessionCost += cost;
  if (tokens is num) _sessionTokens += tokens.toInt();
  debugPrint(
    'AI_USAGE $what: ${usage['calls']} call(s), models=${usage['models']}, '
    'in=${usage['promptTokens']} out=${usage['outputTokens']} '
    'total=${usage['totalTokens']} tokens, est. cost ${money(cost)} | '
    'since app start: $_sessionTokens tokens, ${money(_sessionCost)}',
  );
}
