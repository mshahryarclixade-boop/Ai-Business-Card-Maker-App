// lib/app/modules/onboarding/model/onboarding_model.dart
import 'package:flutter/widgets.dart';

class OnboardingModel {
  final Widget Function() topBuilder; // custom top graphic per screen
  final String title;
  final String subtitle;

  const OnboardingModel({
    required this.topBuilder,
    required this.title,
    required this.subtitle,
  });
}