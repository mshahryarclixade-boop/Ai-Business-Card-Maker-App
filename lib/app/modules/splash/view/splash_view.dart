import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:get_storage/get_storage.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../onboarding/controller/onboarding_controller.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../../paywall/view/paywall_screen.dart';
import '../../../core/translations/tr_extension.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _progress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _route();
    });
  }

  /// Force-update check first; then the normal routing below. An optional
  /// update prompt is shown on top of wherever the user lands.
  Future<void> _route() async {
    final update = await AppUpdateService.check();
    if (!mounted) return;
    if (update == UpdateType.forced) {
      // Stay on the splash behind a non-dismissible dialog: the app is
      // unusable until the user updates.
      await AppUpdateService.showUpdateDialog(forced: true);
      return;
    }
    await _navigate();
    if (update == UpdateType.optional) {
      AppUpdateService.showUpdateDialog(forced: false);
    }
  }

  /// First launch: onboarding. Afterwards: home for subscribers, and the
  /// paywall for everyone else while Remote Config has it enabled.
  Future<void> _navigate() async {
    final seen = GetStorage().read<bool>(OnboardingController.seenKey) ?? false;
    if (!seen) {
      Get.offAllNamed(Routes.ONBOARDING);
      return;
    }
    // Wait (bounded) for the store's real answer; falls back to the cached
    // state if it's slow or offline.
    try {
      await Get.find<SubscriptionController>().awaitSync().timeout(
        const Duration(seconds: 4),
      );
    } catch (_) {}
    if (!mounted) return;
    final paywall = RemoteConfigService().paywallConfig;
    if (Get.find<SubscriptionController>().isPro ||
        !paywall.enabled ||
        !paywall.showOnLaunch) {
      Get.offAllNamed(Routes.MAIN);
    } else {
      AnalyticsService.logPaywallShown('launch');
      Get.offAllNamed(
        Routes.PAYWALL,
        arguments: const PaywallArgs(source: 'launch', isLaunch: true),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 26),
              // Logo (exported with its own background and padding)
              ClipRRect(
                borderRadius: BorderRadius.circular(21.32),
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  width: 151,
                  height: 151,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'splash_title'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0,
                    color: AppColors.splashTextPrimary,
                  ),
                ),
              ),
              const Spacer(flex: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 19),
                child: Text(
                  'splash_tagline'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: 0,
                    color: AppColors.splashTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'splash_subtitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 22 / 14,
                  letterSpacing: 0,
                  color: AppColors.splashTextSecondary,
                ),
              ),
              const SizedBox(height: 13),
              // Progress indicator, still driven by the same _progress animation
              AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  return SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      value: _progress.value,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      color: AppColors.splashProgress,
                      backgroundColor: Colors.transparent,
                    ),
                  );
                },
              ),
              const SizedBox(height: 54),
            ],
          ),
        ),
      ),
    );
  }
}
