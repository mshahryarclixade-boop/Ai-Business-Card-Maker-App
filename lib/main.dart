import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/core/services/connectivity_service.dart';
import 'app/core/services/recent_designs_service.dart';
import 'app/modules/profile/controller/profile_controller.dart';
import 'app/core/services/notification_service.dart';
import 'app/core/services/remote_config_service.dart';
import 'app/modules/paywall/controller/credits_controller.dart';
import 'app/modules/paywall/controller/subscription_controller.dart';
import 'app/modules/paywall/services/revenue_cat_service.dart';
import 'app/modules/paywall/services/user_credits_manager.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidPlayIntegrityProvider(),
    providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  // Crashlytics: collect only in release builds.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await GetStorage.init();
  await NotificationService().init();

  // Remote Config must be ready before credit pools are read; bounded so a
  // slow network never stalls launch (defaults apply).
  await RemoteConfigService().init().timeout(
    const Duration(seconds: 5),
    onTimeout: () {},
  );
  await RevenueCatHelper().initPlatformState();
  // Hydrates the credit balance (Firestore) in the background.
  UserCreditsManager().initUser().catchError((Object _) {});
  Get.put(SubscriptionController(), permanent: true);
  Get.put(CreditsController(), permanent: true);
  Get.put(ConnectivityService(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  await Get.putAsync(() => RecentDesignsService().init());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Business Card Maker',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      // Analytics: logs screen views automatically.
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}