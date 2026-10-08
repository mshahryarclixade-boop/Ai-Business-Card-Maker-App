import 'package:get/get.dart';

import '../modules/main_nav/view/main_nav_view.dart';
import '../modules/onboarding/view/onboarding_view_v2.dart';
import '../modules/profile_setup/view/business_details_view.dart';
import '../modules/profile_setup/view/personal_details_view.dart';
import '../modules/recent designs/view/my_cards_view.dart';
import '../modules/splash/view/splash_view.dart';
import '../modules/template/widget/template_edit_view.dart';
import 'app_routes.dart';
import '../modules/profile_setup/view/first_card_generating_view.dart';
import '../modules/profile_setup/view/first_card_ready_view.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(name: Routes.SPLASH, page: () => const SplashView()),
    GetPage(name: Routes.ONBOARDING, page: () => const OnboardingViewV2()),
    GetPage(name: Routes.PERSONAL_DETAILS, page: () => const PersonalDetailsView(),),
    GetPage(name: Routes.MAIN, page: () => const MainNavView()),
    GetPage(name: Routes.TEMPLATE_EDIT, page: () => const TemplateEditView()),
    GetPage(name: Routes.MY_CARDS, page: () => const MyCardsView()),
    GetPage(name: Routes.BUSINESS_DETAILS, page: () => const BusinessDetailsView(),),
    GetPage(name: Routes.FIRST_CARD, page: () => const FirstCardGeneratingView(),),
    GetPage(name: Routes.FIRST_CARD_READY, page: () => const FirstCardReadyView(),),
  ];
}