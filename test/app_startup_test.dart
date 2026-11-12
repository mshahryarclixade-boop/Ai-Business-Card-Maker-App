import 'dart:async';
import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/app_startup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing started (tests, hot restart): ready is already complete', () async {
    await AppStartup.ready.timeout(const Duration(seconds: 1));
  });

  test('the slow work runs in the background; ready completes when it ends, '
      'also when it fails', () async {
    final gate = Completer<void>();
    var finished = false;
    AppStartup.run(() async {
      await gate.future;
      finished = true;
      throw Exception('a service failed');
    });
    var ready = false;
    unawaited(AppStartup.ready.then((_) => ready = true));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(ready, isFalse); // run() returned at once: the first frame is not held
    gate.complete();
    await AppStartup.ready.timeout(const Duration(seconds: 1));
    expect(finished, isTrue);
  });

  test('main() only awaits what the first frame needs; the splash waits for the '
      'rest only when it routes', () {
    final main = File('lib/main.dart').readAsStringSync();
    final body = main.substring(main.indexOf('void main()'), main.indexOf('Future<void> _initServices'));
    for (final slow in ['RemoteConfigService', 'RevenueCatHelper', 'UserCreditsManager',
        'NotificationService', 'FirebaseAppCheck', 'RecentDesignsService']) {
      expect(body.contains(slow), isFalse, reason: '$slow must not block runApp');
    }
    expect(body.indexOf('AppStartup.run'), lessThan(body.indexOf('runApp(')));
    final splash = File('lib/app/modules/splash/view/splash_view.dart').readAsStringSync();
    expect(splash, contains('await AppStartup.ready;'));
    final strings = File('lib/app/core/translations/app_strings.dart').readAsStringSync();
    expect(strings, contains('unawaited('));
  });
}
