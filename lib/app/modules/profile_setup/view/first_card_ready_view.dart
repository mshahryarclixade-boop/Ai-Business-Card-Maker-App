import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../widgets/profile_primary_button.dart';

class FirstCardReadyView extends StatelessWidget {
  const FirstCardReadyView({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = (Get.arguments as List<Uint8List>?) ?? const <Uint8List>[];

    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your First Card\nis ready',
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
                    const Text(
                      'We’ve added your details to a\nclean starting design. '
                          'Now make it your\nown.',
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
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: _CardPreview(bytes: bytes),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ProfilePrimaryButton(
                label: 'Go to Home',
                showArrow: false,
                onTap: () => Get.offAllNamed(Routes.MAIN),
              ),
            ),
          ],
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