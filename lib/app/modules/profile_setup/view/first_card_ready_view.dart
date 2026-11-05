import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../widgets/profile_primary_button.dart';
import '../widgets/profile_setup_layout.dart';
import '../../../core/translations/tr_extension.dart';

class FirstCardReadyView extends StatelessWidget {
  const FirstCardReadyView({super.key});

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
          footer: ProfilePrimaryButton(
            label: 'profile_setup_ready_go_home'.tr,
            showArrow: false,
            onTap: () => Get.offAllNamed(Routes.MAIN),
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
