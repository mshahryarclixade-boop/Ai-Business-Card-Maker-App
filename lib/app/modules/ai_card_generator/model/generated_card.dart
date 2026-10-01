
class GeneratedCard {
  final String frontImagePath;
  final String backImagePath;

  final String? frontBackgroundPath;
  final String? backBackgroundPath;
  final List<Map<String, dynamic>>? frontElements;
  final List<Map<String, dynamic>>? backElements;

  const GeneratedCard({
    required this.frontImagePath,
    required this.backImagePath,
    this.frontBackgroundPath,
    this.backBackgroundPath,
    this.frontElements,
    this.backElements,
  });

  bool get hasEditableFront =>
      frontBackgroundPath != null && frontElements != null;

  bool get hasEditableBack =>
      backBackgroundPath != null && backElements != null;
}