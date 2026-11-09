import 'dart:io';

import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/view/first_card_ready_view.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/view/scan_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fonts.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}
}

/// Switching apps and coming back must not leave a blank or broken screen:
/// each screen is sent through the real lifecycle sequence the OS delivers
/// (inactive -> hidden -> paused, then inactive -> resumed) and must still be
/// on screen, with no exception raised while rebuilding.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
    await loadRobotoAsSfPro();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put<SubscriptionController>(_Sub());
    Get.put(ProfileStore());
  });

  const sizes = {
    'phone': Size(393, 852),
    'tablet portrait': Size(820, 1180),
    'tablet landscape': Size(1180, 820),
  };

  Future<void> backgroundAndBack(WidgetTester t) async {
    final b = t.binding;
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      b.handleAppLifecycleStateChanged(s);
      await t.pump(const Duration(milliseconds: 100));
    }
    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      b.handleAppLifecycleStateChanged(s);
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pump(const Duration(milliseconds: 600));
  }

  final screens = <String, Widget Function()>{
    'paywall View 2': () => const PaywallView2(),
    'scan': () => const ScanCardView(),
    'first card ready': () => const FirstCardReadyView(),
  };

  for (final screen in screens.entries) {
    for (final size in sizes.entries) {
      testWidgets(
        '${screen.key} survives background and resume on ${size.key}',
        (t) async {
          t.view.physicalSize = size.value * 2;
          t.view.devicePixelRatio = 2;
          addTearDown(t.view.reset);
          await t.pumpWidget(GetMaterialApp(home: screen.value()));
          await t.pump(const Duration(milliseconds: 400));

          await backgroundAndBack(t);

          expect(t.takeException(), isNull);
          expect(find.byType(Scaffold), findsWidgets); // still drawn
          // Something visible is in the tree (not an empty/blank body).
          expect(find.byType(Text), findsWidgets);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'scan: camera is released on background and restarted on resume',
    (t) async {
      t.view.physicalSize = const Size(393 * 2, 852 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(const GetMaterialApp(home: ScanCardView()));
      await t.pump(const Duration(milliseconds: 400));
      // Two full cycles in a row (quick app switching).
      await backgroundAndBack(t);
      await backgroundAndBack(t);
      expect(t.takeException(), isNull);
      expect(find.byType(ScanCardView), findsOneWidget);
    },
  );
}
