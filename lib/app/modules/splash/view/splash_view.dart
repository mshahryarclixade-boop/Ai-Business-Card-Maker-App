import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../onboarding/controller/onboarding_controller.dart';

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

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();


    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Onboarding is only shown the first time. After that the flag is
        // true and we go straight to the app.
        final seen =
            GetStorage().read<bool>(OnboardingController.seenKey) ?? false;
        Get.offAllNamed(seen ? Routes.MAIN : Routes.ONBOARDING);
      }
    });
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'AI Business\nCard Maker',
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 19),
                child: Text(
                  'Your Next First Impression',
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
              const Text(
                'SMART CARDS REAL CONNECTIONS',
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