// test/connectivity_service_test.dart
//
// Assumes the service lives at lib/app/core/services/ (as its header comment
// says). Adjust the import if the folder differs.

import 'package:ai_business_card_maker/app/core/services/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';


ConnectivityService _service(List<bool> results) {
  final s = ConnectivityService()
    ..confirmDelay = Duration.zero
    ..probe = (() async => results.length > 1 ? results.removeAt(0) : results.first);
  return s;
}

/// startMonitoring() runs its first check in the background; let it finish.
Future<void> _start(ConnectivityService s) async {
  s.startMonitoring();
  await pumpEventQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('not blocked before monitoring starts', () {
    final s = _service([false]);
    expect(s.isBlocked, isFalse);
  });

  test('real internet: stays online and unblocked', () async {
    final s = _service([true]);
    await _start(s);
    expect(s.isOnline.value, isTrue);
    expect(s.isBlocked, isFalse);
  });

  test('no real internet (e.g. Wi-Fi without data): blocked', () async {
    final s = _service([false]);
    await _start(s);
    expect(s.isOnline.value, isFalse);
    expect(s.isBlocked, isTrue);
  });

  test('one failed probe followed by a success does not lock the app', () async {
    // First call fails, the confirmation call succeeds.
    final s = _service([false, true]);
    await _start(s);
    expect(s.isOnline.value, isTrue);
    expect(s.isBlocked, isFalse);
  });

  test('unlocks by itself when internet returns', () async {
    final results = <bool>[false];
    final s = ConnectivityService()
      ..confirmDelay = Duration.zero
      ..probe = (() async => results.first);
    await _start(s);
    expect(s.isBlocked, isTrue);

    results[0] = true;
    await s.evaluateNow();
    expect(s.isOnline.value, isTrue);
    expect(s.isBlocked, isFalse);
  });

  test('retry() reports the real state and unlocks on success', () async {
    final results = <bool>[false];
    final s = ConnectivityService()
      ..confirmDelay = Duration.zero
      ..probe = (() async => results.first);
    await _start(s);

    expect(await s.retry(), isFalse);
    expect(s.isBlocked, isTrue);

    results[0] = true;
    expect(await s.retry(), isTrue);
    expect(s.isBlocked, isFalse);
  });
}