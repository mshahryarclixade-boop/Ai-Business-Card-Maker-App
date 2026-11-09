import 'package:ai_business_card_maker/app/core/services/connectivity_service.dart';
import 'package:ai_business_card_maker/app/core/services/offline_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int opened;
  late ConnectivityService service;

  Future<void> boot(WidgetTester t, {required bool online}) async {
    Get.reset();
    opened = 0;
    service = ConnectivityService()
      ..confirmDelay = Duration.zero
      ..probe = () async => online;
    Get.put(service);
    await t.pumpWidget(
      GetMaterialApp(
        builder: (context, child) => OfflineGate(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Center(
            child: ElevatedButton(onPressed: () => opened++, child: const Text('Open feature')),
          ),
        ),
      ),
    );
    service.startMonitoring();
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 400));
  }

  Finder dialog() => find.byIcon(Icons.wifi_off_rounded);

  Future<void> close(WidgetTester t) async {
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
  }

  testWidgets('offline: a tap on any feature shows the dialog and does not open it', (t) async {
    await boot(t, online: false);
    expect(dialog(), findsOneWidget, reason: 'it opens when the connection is lost');
    await close(t);
    expect(dialog(), findsNothing);

    await t.tap(find.text('Open feature'));
    await t.pumpAndSettle();
    expect(opened, 0, reason: 'no feature access while offline');
    expect(dialog(), findsOneWidget, reason: 'the tap brings the dialog back');
    await close(t);
    service.onClose(); // stops its polling timer before the test ends
  });

  testWidgets('Close is only temporary: every further tap shows the dialog again', (t) async {
    await boot(t, online: false);
    await close(t);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Open feature'));
      await t.pumpAndSettle();
      expect(dialog(), findsOneWidget, reason: 'tap ${i + 1}');
      await close(t);
    }
    expect(opened, 0);
    service.onClose(); // stops its polling timer before the test ends
  });

  testWidgets('there is never more than one dialog', (t) async {
    await boot(t, online: false);
    // Taps while the dialog is up (on the dialog's own backdrop is a close; here
    // the app behind is touched through the gate).
    service.showNoInternetDialog();
    service.showNoInternetDialog();
    await t.pump(const Duration(milliseconds: 300));
    expect(dialog(), findsOneWidget);
    await close(t);
    service.onClose(); // stops its polling timer before the test ends
  });

  testWidgets('the system Back button is blocked too (dialog instead of going back)', (t) async {
    await boot(t, online: false);
    await close(t);
    final handled = await WidgetsBinding.instance.handlePopRoute();
    await t.pump(const Duration(milliseconds: 300));
    expect(handled, isTrue);
    expect(dialog(), findsOneWidget);
    await close(t);
    service.onClose(); // stops its polling timer before the test ends
  });

  testWidgets('when the internet returns the app unlocks by itself', (t) async {
    await boot(t, online: false);
    await close(t);
    service.probe = () async => true;
    await service.evaluateNow();
    await t.pump(const Duration(milliseconds: 200));
    expect(service.isBlocked, isFalse);

    await t.tap(find.text('Open feature'));
    await t.pump();
    expect(opened, 1);
    expect(dialog(), findsNothing);
    service.onClose(); // stops its polling timer before the test ends
  });

  testWidgets('online: nothing is blocked and no dialog appears', (t) async {
    await boot(t, online: true);
    await t.tap(find.text('Open feature'));
    await t.pump();
    expect(opened, 1);
    expect(dialog(), findsNothing);
    service.onClose(); // stops its polling timer before the test ends
  });
}
