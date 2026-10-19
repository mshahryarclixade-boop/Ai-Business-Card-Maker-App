
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExperienceEntry {
  final companyController = TextEditingController();
  final roleController = TextEditingController();
  final tenureController = TextEditingController();

  Map<String, String> toMap() {
    return {
      'company': companyController.text.trim(),
      'role': roleController.text.trim(),
      'tenure': tenureController.text.trim(),
    };
  }

  bool get isEmpty =>
      companyController.text.trim().isEmpty &&
          roleController.text.trim().isEmpty &&
          tenureController.text.trim().isEmpty;

  void dispose() {
    companyController.dispose();
    roleController.dispose();
    tenureController.dispose();
  }
}

class ProfileBuilderController extends GetxController {
  static const int maxAudience = 3;

  final List<String> goals = const [
    'Get hired',
    'Win clients',
    'Raise funding',
    'Build authority',
  ];

  final List<String> audiences = const [
    'Startup founders',
    'Recruiters',
    'Product managers',
    'Agencies',
    'Investors',
    'Small businesses',
  ];

  final RxString selectedGoal = 'Win clients'.obs;

  final RxList<String> selectedAudiences = <String>[
    'Startup founders',
    'Product managers',
  ].obs;

  final industryController = TextEditingController();
  final tenureController = TextEditingController();

  final List<ExperienceEntry> experiences = [];

  void selectGoal(String goal) {
    selectedGoal.value = goal;
  }

  void toggleAudience(String audience) {
    if (selectedAudiences.contains(audience)) {
      selectedAudiences.remove(audience);
    } else if (selectedAudiences.length < maxAudience) {
      selectedAudiences.add(audience);
    }
  }

  void addExperience() {
    experiences.add(ExperienceEntry());
    update();
  }

  void removeExperience(int index) {
    if (index < 0 || index >= experiences.length) return;

    experiences[index].dispose();
    experiences.removeAt(index);
    update();
  }

  List<Map<String, String>> get experienceData {
    return experiences
        .where((experience) => !experience.isEmpty)
        .map((experience) => experience.toMap())
        .toList();
  }

  Map<String, dynamic> get profileData {
    return {
      'goal': selectedGoal.value,
      'audiences': selectedAudiences.toList(),
      'industry': industryController.text.trim(),
      'tenure': tenureController.text.trim(),
      'experiences': experienceData,
    };
  }

  @override
  void onClose() {
    industryController.dispose();
    tenureController.dispose();

    for (final experience in experiences) {
      experience.dispose();
    }

    super.onClose();
  }
}
