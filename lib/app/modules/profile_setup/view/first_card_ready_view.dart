import '../../../core/services/recent_designs_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../paywall/services/onboarding_experiment.dart';
import '../../paywall/services/paywall_triggers.dart';
import '../../main_nav/controller/main_nav_controller.dart';
import '../widgets/profile_primary_button.dart';
import '../widgets/profile_setup_layout.dart';
import '../../../core/translations/tr_extension.dart';

class FirstCardReadyView extends StatelessWidget {
  const FirstCardReadyView({super.key});

  /// The first card is saved (so it can be shared).
  bool get _hasSavedCard {
    _alwaysObservable.value; // Obx needs something observable to watch
    return Get.isRegistered<RecentDesignsService>() &&
        Get.find<RecentDesignsService>().designs.isNotEmpty;
  }

  static final _alwaysObservable = false.obs;

  /// 50/50 test: half of the users see the (skippable) paywall here; closing
  /// it - or not seeing it - goes on to Home and the chosen next step.
  Future<void> _continue(FirstCardNext next) async {
    if (OnboardingExperiment().showsPaywall) {
      await PaywallTriggers.show(PaywallTrigger.onboarding, screen: 'first_card_ready');
    }
    MainNavController.pendingFirstCardAction = next;
    Get.offAllNamed(Routes.MAIN);
  }

  @override
  Widget build(BuildContext context) {
    final tablet = isProfileTablet(context);
    final cards = (Get.arguments as List<Uint8List>?) ?? const <Uint8List>[];

    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: ProfileSetupLayout(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          dismissKeyboardOnDrag: false,
          scroll: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile_setup_ready_title'.tr,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: 0,
                  color: AppColors.splashTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'profile_setup_ready_subtitle'.tr,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 26 / 20,
                  letterSpacing: 0,
                  color: AppColors.splashTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              for (final bytes in cards) ...[
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: tablet ? 520 : 300),
                    child: _CardPreview(bytes: bytes),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
          // What to do next with the first card: scan someone's card, or
          // share your own.
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfilePrimaryButton(
                label: 'profile_setup_ready_scan'.tr,
                showArrow: false,
                onTap: () => _continue(FirstCardNext.scan),
              ),
              const SizedBox(height: 12),
              // Sharing needs the saved card: until it is there the button is
              // dimmed and says why instead of doing nothing.
              Obx(() {
                final ready = _hasSavedCard;
                return Opacity(
                  opacity: ready ? 1 : 0.5,
                  child: _SecondaryButton(
                    label: 'profile_setup_ready_share'.tr,
                    onTap: ready
                        ? () => _continue(FirstCardNext.share)
                        : () => showAppSnackbar(
                            'profile_setup_ready_share_unavailable_title'.tr,
                            'profile_setup_ready_share_unavailable'.tr,
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.onboardingCardShadow,
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(bytes, fit: BoxFit.contain),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(500),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 22 / 18,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
