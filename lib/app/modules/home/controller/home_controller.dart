import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/connectivity_service.dart';
// import '../../../core/widgets/rate_app_dialog.dart'; // uncomment to test the rate dialog

class HomeController extends GetxController {
  final TextEditingController promptController = TextEditingController();

  @override
  void onReady() {
    super.onReady();

    // Home is the first screen where the No Internet dialog is allowed
    // (it stays silent on splash / onboarding).
    Get.find<ConnectivityService>().startMonitoring();

    // TEMP: testing only — uncomment to preview the rate dialog on Home.
    // showRateAppDialog(
    //   onYes: (rating) => debugPrint('Rated: $rating stars'),
    //   onNo: () => debugPrint('Pressed No'),
    // );
  }

  Future<void> onGenerateWithAi() async {
    // Shows the No Internet dialog and stops here if there's no connection.
    if (!await Get.find<ConnectivityService>().ensureInternet()) return;

    // TODO: hook up to AI generation service later
  }

  @override
  void onClose() {
    promptController.dispose();
    super.onClose();
  }
}