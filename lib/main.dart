import 'dart:ui';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart' hide Trans;
import 'package:get_storage/get_storage.dart';
import 'app/core/translations/app_strings.dart';
import 'app/core/services/connectivity_service.dart';
import 'app/core/services/recent_designs_service.dart';
import 'app/modules/profile/controller/profile_controller.dart';
import 'app/core/services/notification_service.dart';
import 'app/core/services/remote_config_service.dart';
import 'app/modules/paywall/controller/credits_controller.dart';
import 'app/modules/paywall/controller/subscription_controller.dart';
import 'app/modules/paywall/services/revenue_cat_service.dart';
import 'app/modules/paywall/services/user_credits_manager.dart';
import 'app/modules/career_studio/controller/career_score_store.dart';
import 'app/modules/career_studio/controller/generated_profile_store.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';
import 'app/core/translations/tr_extension.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStrings.init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidPlayIntegrityProvider(),
    providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  // Crashlytics: collect only in release builds.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await GetStorage.init();
  CareerScoreStore.load();
  GeneratedProfileStore.load();
  await NotificationService().init();

  // Remote Config must be ready before credit pools are read; bounded so a
  // slow network never stalls launch (defaults apply).
  await RemoteConfigService().init().timeout(
    const Duration(seconds: 5),
    onTimeout: () {},
  );
  await RevenueCatHelper().initPlatformState();
  // Before SubscriptionController: its first status check may grant a plan
  // pool, and a new user's free-tier record written after that would
  // overwrite it. Bounded so a slow network never stalls launch (initUser
  // keeps a local guess and reconciles later).
  await UserCreditsManager()
      .initUser()
      .timeout(const Duration(seconds: 5), onTimeout: () {})
      .catchError((Object _) {});
  Get.put(SubscriptionController(), permanent: true);
  Get.put(CreditsController(), permanent: true);
  Get.put(ConnectivityService(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  await Get.putAsync(() => RecentDesignsService().init());

  // Clarity wraps the app only; it starts after every service above is up.
  // No custom user id is set, so sessions use Clarity's random anonymous id.
  runApp(
    ClarityWidget(
      clarityConfig: ClarityConfig(projectId: _clarityProjectId),
      app: const MyApp(),
    ),
  );
}

/// Microsoft Clarity project id (not a secret).
const _clarityProjectId = 'yxjxedb90f';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    AppStrings.changes.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    AppStrings.changes.removeListener(_onLanguageChanged);
    super.dispose();
  }

  /// Language picked in Settings: GetMaterialApp keeps its own locale once
  /// built, so push the new one (this also flips text direction live).
  void _onLanguageChanged() => Get.updateLocale(_frameworkLocale);

  static bool _frameworkSupports(Locale l) =>
      GlobalMaterialLocalizations.delegate.isSupported(l);

  /// The app language when Flutter's built-in labels/direction support it
  /// (they do for every RTL language we ship); English otherwise, since a
  /// locale the Material delegate can't load would throw.
  static Locale get _frameworkLocale => _frameworkSupports(AppStrings.locale)
      ? AppStrings.locale
      : const Locale(AppStrings.fallbackLanguage);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // The app language (device language on first install) drives text
      // direction and the Material/Cupertino built-in labels.
      locale: _frameworkLocale,
      fallbackLocale: const Locale(AppStrings.fallbackLanguage),
      supportedLocales: AppStrings.supportedLocales
          .where(_frameworkSupports)
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (_) => 'app_title'.tr,
      theme: ThemeData(fontFamily: 'SFPro'),
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      // Cards, contacts and scans are personal data: mask the whole app in
      // Clarity recordings. Individual screens opt out with ClarityUnmask.
      builder: (context, child) =>
          ClarityMask(child: child ?? const SizedBox.shrink()),
      // Analytics: logs screen views automatically.
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}
