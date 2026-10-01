import 'package:get/get.dart';

import '../modules/main_nav/view/main_nav_view.dart';
import '../modules/onboarding/view/onboarding_view.dart';
import '../modules/recent designs/view/my_cards_view.dart';
import '../modules/splash/view/splash_view.dart';
import '../modules/template/widget/template_edit_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(name: Routes.SPLASH, page: () => const SplashView()),
    GetPage(name: Routes.ONBOARDING, page: () => const OnboardingView()),
    GetPage(name: Routes.MAIN, page: () => const MainNavView()),
    GetPage(name: Routes.TEMPLATE_EDIT, page: () => const TemplateEditView()),
    GetPage(name: Routes.MY_CARDS, page: () => const MyCardsView()), // ADDED
  ];
}