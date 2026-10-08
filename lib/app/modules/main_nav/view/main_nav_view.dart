import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/view/home_view.dart';
import '../../template/controller/template_controller.dart';
import '../../template/view/template_view.dart';
import '../controller/main_nav_controller.dart';
import '../../profile/view/profile_view.dart';
import '../../contacts/view/contacts_view.dart';
import '../widgets/main_bottom_nav_bar.dart';

const double _kDialogWidth = 332;
const double _kDialogMinHeight = 188;
const double _kDialogRadius = 24;
const double _kDialogSideMargin = 31;
const EdgeInsets _kDialogPadding = EdgeInsets.fromLTRB(24, 20, 24, 20);
const double _kSectionGap = 24;

const double _kButtonWidth = 120;
const double _kButtonHeight = 32;
const double _kButtonRadius = 8;
const double _kButtonGap = 10;
// ---------------------------------------------------------------------------

class MainNavView extends GetView<MainNavController> {
  const MainNavView({super.key});

  Future<void> _handleBack() async {
    // Template tab: close the open template preview first.
    if (controller.tabIndex.value == 1 &&
        Get.isRegistered<TemplateController>() &&
        Get.find<TemplateController>().selectedTemplate.value != null) {
      Get.find<TemplateController>().closeTemplateDetail();
      return;
    }

    // Any other tab: go to Home.
    if (controller.tabIndex.value != 0) {
      controller.changeTab(0);
      return;
    }

    // Already on Home: ask before exiting.
    final shouldExit = await _showExitDialog();

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Future<bool?> _showExitDialog() {
    return Get.dialog<bool>(
      Center(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _kDialogSideMargin,
            ),
            child: Container(
              width: _kDialogWidth,
              constraints: const BoxConstraints(
                minHeight: _kDialogMinHeight,
              ),
              padding: _kDialogPadding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_kDialogRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.exit_to_app_rounded,
                    size: 40,
                    color: AppColors.titleDark,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Exit App',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Are you sure you want to exit?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w400,
                      color: AppColors.titleDark,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: _kSectionGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: _kButtonWidth,
                        height: _kButtonHeight,
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F1F3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _kButtonRadius,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.titleDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: _kButtonGap),
                      SizedBox(
                        width: _kButtonWidth,
                        height: _kButtonHeight,
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _kButtonRadius,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Exit',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(MainNavController());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,

        // No bottomNavigationBar here.
        // The navigation pill is placed directly over the body
        // so Scaffold cannot create a rectangular bottom-nav area.
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Obx(
                    () => IndexedStack(
                  index: controller.tabIndex.value,
                  children: const [
                    HomeView(),
                    TemplateView(),
                    ContactsView(),
                    ProfileView(),
                  ],
                ),
              ),
            ),

            // Floating bottom navigation pill.
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Obx(
                        () => MainBottomNavBar(
                      currentIndex: controller.tabIndex.value,
                      onTabSelected: controller.onNavTap,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}