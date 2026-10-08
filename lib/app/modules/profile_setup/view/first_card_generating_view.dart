import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/first_card_controller.dart';
import '../widgets/first_card_widgets.dart';
import '../widgets/profile_primary_button.dart';

class FirstCardGeneratingView extends GetView<FirstCardController> {
  const FirstCardGeneratingView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(FirstCardController());

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.firstCardBackground),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 28),
              const Text(
                'A Little Magic in progress',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: 0,
                  color: AppColors.profileStepActive,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Preparing Your\nFirst Card',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0,
                    color: AppColors.splashTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const FirstCardLoadingVideo(),
              const SizedBox(height: 56),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Obx(
                      () => controller.status.value == FirstCardStatus.failed
                      ? _FailureBlock(controller: controller)
                      : _ProgressRows(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRows extends StatelessWidget {
  const _ProgressRows({required this.controller});

  final FirstCardController controller;

  @override
  Widget build(BuildContext context) {
    final personal = controller.personalDone.value;
    final company = controller.companyDone.value;
    final hasCompany = controller.hasCompanyDetails;

    // The row that is currently loading. Rows after it wait (faded),
    // rows before it are done (tick).
    final companyActive = personal && hasCompany && !company;
    final creatingActive = personal && (company || !hasCompany);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepRow(
          text: 'Your Personal details added',
          done: personal,
          active: !personal,
        ),
        if (hasCompany) ...[
          const SizedBox(height: 22),
          _StepRow(
            text: 'Your Company details added',
            done: company,
            active: companyActive,
          ),
        ],
        const SizedBox(height: 22),
        _StepRow(
          text: 'Creating your first design...',
          done: false,
          active: creatingActive,
          highlight: true,
        ),
      ],
    );
  }
}

/// A status row that is faded until its turn, then loads, then gets a tick.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.text,
    required this.done,
    required this.active,
    this.highlight = false,
  });

  final String text;
  final bool done;
  final bool active;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final waiting = !done && !active;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: waiting ? 0.35 : 1,
      child: FirstCardStatusRow(
        text: text,
        done: done,
        highlight: highlight,
      ),
    );
  }
}

class _FailureBlock extends StatelessWidget {
  const _FailureBlock({required this.controller});

  final FirstCardController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          controller.errorMessage.value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: AppColors.splashTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your details are saved.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.splashTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ProfilePrimaryButton(
          label: 'Try Again',
          showArrow: false,
          onTap: controller.tryAgain,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: controller.useFreeTemplate,
          child: const Text(
            'Use a Free Template',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.profileStepActive,
            ),
          ),
        ),
      ],
    );
  }
}