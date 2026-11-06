import 'package:ai_business_card_maker/app/core/services/connectivity_service.dart';
import 'package:ai_business_card_maker/app/core/services/gemini_card_service.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/service/career_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int opened;

  Future<ConnectivityService> boot(WidgetTester t, {required bool online}) async {
    Get.reset();
    opened = 0;
    final s = ConnectivityService()..probe = () async => online;
    Get.put(s);
    await t.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(onPressed: () => opened++, child: const Text('Open feature')),
          ),
        ),
      ),
    );
    return s;
  }

  Finder dialog() => find.byIcon(Icons.wifi_off_rounded);

  testWidgets('offline at start: the dialog pops up once; closing it frees the app', (t) async {
    final s = await boot(t, online: false);
    s.startMonitoring(); // what Home does on start
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 300));
    expect(dialog(), findsOneWidget, reason: 'the No Internet dialog is shown');

    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    expect(dialog(), findsNothing);

    // The app works: the feature opens.
    await t.tap(find.text('Open feature'));
    expect(opened, 1);
  });

  testWidgets('it does not come back on every network event, nor block the next taps', (t) async {
    final s = await boot(t, online: false);
    s.startMonitoring();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();

    // The connection flaps while still offline: several more checks.
    for (var i = 0; i < 4; i++) {
      s.startMonitoring(); // no-op; the real listener calls the same check
      await s.retry(); // still offline
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(dialog(), findsNothing, reason: 'shown once per offline period');
    await t.tap(find.text('Open feature'));
    expect(opened, 1);
  });

  testWidgets('coming back online and dropping again shows it again', (t) async {
    final s = await boot(t, online: false);
    s.startMonitoring();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();

    s.probe = () async => true;
    expect(await s.retry(), isTrue);
    expect(s.isOnline.value, isTrue);

    s.probe = () async => false;
    final again = s.ensureInternet(); // an online-only action while offline
    await t.pump(const Duration(milliseconds: 300));
    expect(await again, isFalse);
    expect(dialog(), findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
  });

  testWidgets('an AI request offline opens the dialog and sends nothing', (t) async {
    await boot(t, online: false);
    Object? error;
    final call = CloudCareerAi().call('coachReply', {}).catchError((Object e) {
      error = e;
      return <String, dynamic>{};
    });
    await t.pump(const Duration(milliseconds: 300));
    await call;
    expect(error, isA<GeminiException>());
    expect(dialog(), findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
  });
}
