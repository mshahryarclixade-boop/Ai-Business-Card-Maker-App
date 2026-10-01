import 'package:ai_business_card_maker/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/remove_background_controller.dart';
import 'confirm_screen.dart';
import 'initial_screen.dart';
import 'processing_screen.dart';
import 'result_screen.dart';

class RemoveBackgroundView extends GetView<RemoveBackgroundController> {
  const RemoveBackgroundView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RemoveBackgroundController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          switch (controller.state.value) {
            case RemoveBgState.initial:
              return const InitialScreen();

            case RemoveBgState.confirm:
              return const ConfirmScreen();

            case RemoveBgState.processing:
              return const ProcessingScreen();

            case RemoveBgState.result:
              return const ResultScreen();
          }
        }),
      ),
    );
  }
}