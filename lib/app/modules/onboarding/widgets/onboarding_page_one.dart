import 'package:flutter/material.dart';

import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import 'onboarding_constrained.dart';
import 'onboarding_feature_tile.dart';

class OnboardingPageOne extends StatelessWidget {
  const OnboardingPageOne({super.key});

  @override
  Widget build(BuildContext context) {
    final tablet = isTabletWidth(context);
    final config = RemoteConfigService().onboardingConfig;

    final title = Text(
      config.title,
      maxLines: tablet ? 1 : null,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 35,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0,
        color: AppColors.splashTextPrimary,
      ),
    );

    final subtitle = Text(
      config.subtitle,
      maxLines: tablet ? 1 : null,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        height: 1.3,
        color: AppColors.splashTextPrimary,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: tablet ? 24 : 12),
          // No background card behind the image anymore, and it is larger.
          SizedBox(
            height: tablet ? 360 : 230,
            width: double.infinity,
            child: Image.asset(
              'assets/images/onboarding1_image.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          // Tablets: one line each (shrinks to fit instead of wrapping).
          // Phones: wraps as before.
          if (tablet)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: title,
            )
          else
            title,
          if (config.subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (tablet)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: subtitle,
              )
            else
              subtitle,
          ],
          const SizedBox(height: 16),
          for (int i = 0; i < onboardingPage1Features.length; i++) ...[
            OnboardingFeatureTile(feature: onboardingPage1Features[i]),
            if (i != onboardingPage1Features.length - 1)
              const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }
}