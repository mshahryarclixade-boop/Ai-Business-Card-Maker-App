enum TemplateOrientation { horizontal, vertical }

class TemplateItem {
  final String id;

  final String name;

  final List<String> keywords;

  final String category;

  final TemplateOrientation orientation;

  final String frontImagePath;
  final String backImagePath;

  final bool isPremium;

  // ── Placeholders for the EDIT / AUTO-FILL phase

  final String? noTextFrontImagePath;
  final String? noTextBackImagePath;
  final List<TemplateTextField>? textFields;

  const TemplateItem({
    required this.id,
    required this.name,
    required this.category,
    required this.orientation,
    required this.frontImagePath,
    required this.backImagePath,
    this.keywords = const [],
    this.isPremium = false,
    this.noTextFrontImagePath,
    this.noTextBackImagePath,
    this.textFields,
  });

  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    if (name.toLowerCase().contains(query)) return true;
    return keywords.any((k) => k.toLowerCase().contains(query));
  }
}

class TemplateTextField {
  final String fieldKey;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontSize;

  const TemplateTextField({
    required this.fieldKey,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fontSize,
  });
}


/// The AI-style first card (purple wave design), shown first in Home's Free
/// Templates. It is drawn live from its own layout like the other templates
/// (see TemplateData.jsonPathFor).
const kAiCardTemplateId = 'ai_first_card';

const kAiCardTemplate = TemplateItem(
  id: kAiCardTemplateId,
  name: 'AI Card',
  category: 'AI',
  orientation: TemplateOrientation.horizontal,
  frontImagePath: 'assets/images/first_card_template.png',
  backImagePath: 'assets/images/first_card_template.png',
);
