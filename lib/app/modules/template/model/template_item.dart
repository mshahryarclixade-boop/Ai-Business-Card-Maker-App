/// Orientation of a template's card layout.
enum TemplateOrientation { horizontal, vertical }

/// A single template.
class TemplateItem {
  /// Stable, human-readable unique id (e.g. "travel_01").

  final String id;

  /// Display name — also used for search matching (e.g. "Travel Agency").
  final String name;

  /// Extra keywords for search, on top of [name]
  /// (e.g. ["marketing", "trip", "flight"]).
  final List<String> keywords;

  /// Must be one of TemplateController.filters, MINUS 'All'
  /// 'All' is only ever a UI filter value, never stored on an item.
  final String category;

  final TemplateOrientation orientation;

  /// Preview images — CURRENT PHASE ONLY (text baked into the image).
  /// Used for both the grid card (front only) and the detail/preview
  /// screen (front + back).
  final String frontImagePath;
  final String backImagePath;

  final bool isPremium;

  // ── Placeholders for the EDIT / AUTO-FILL phase (later work) ──────
  // Left null on purpose for now — nothing in the filters/preview flow
  // reads these yet. When the edit screen is built, these get filled
  // in against the SAME id, so front/back/text-fields all stay bundled
  // on one TemplateItem instead of needing a second lookup.
  //
  //   - noTextFrontImagePath / noTextBackImagePath: background-only
  //     artwork (no text baked in) that auto-fill will draw text onto.
  //   - textFields: position/size/font per field (name, title, company,
  //     phone, email, website, address), split per side, since front
  //     usually has name/title and back has contact details/QR.
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

  /// Case-insensitive search match against [name] and [keywords].
  /// [query] should already be lower-cased + trimmed by the caller.
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    if (name.toLowerCase().contains(query)) return true;
    return keywords.any((k) => k.toLowerCase().contains(query));
  }
}

/// Placeholder shape for a single auto-fill field on a template.
/// Not used yet in the filters/preview phase — defined now so the
/// model doesn't need to change shape again when edit/auto-fill starts.
class TemplateTextField {
  final String fieldKey; // e.g. "name", "title", "phone", "email"
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