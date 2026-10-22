enum FixImpact { high, medium, low }

/// One issue found in the profile. Texts are string keys (UI only: dummy
/// data, no analysis behind it).
class ReportFix {
  const ReportFix({
    required this.id,
    required this.impact,
    required this.points,
    required this.free,
    required this.suggestions,
  });

  final String id;
  final FixImpact impact;
  final int points;

  /// Free users can fix this one (the first two); the rest need Pro.
  final bool free;

  /// Alternatives for "Try another"; the first is shown first.
  final List<String> suggestions;

  /// The score-breakdown part this fix improves (the banner is part of
  /// "photo").
  String get partId => id == 'banner' ? 'photo' : id;

  String get titleKey => 'career_fix_${id}_title';
  String get descKey => 'career_fix_${id}_desc';
  /// Short name for the upgrade sheet ("Unlock the “Featured” fix").
  String get nameKey => 'career_fix_${id}_name';
  String get nowKey => 'career_fix_${id}_now';
  String get impactKey => switch (impact) {
    FixImpact.high => 'career_fix_impact_high',
    FixImpact.medium => 'career_fix_impact_medium',
    FixImpact.low => 'career_fix_impact_low',
  };
}

const kReportFixes = [
  ReportFix(
    id: 'headline',
    impact: FixImpact.high,
    points: 8,
    free: true,
    suggestions: [
      'career_fix_headline_s1',
      'career_fix_headline_s2',
      'career_fix_headline_s3',
    ],
  ),
  ReportFix(
    id: 'about',
    impact: FixImpact.high,
    points: 6,
    free: true,
    suggestions: [
      'career_fix_about_s1',
      'career_fix_about_s2',
      'career_fix_about_s3',
    ],
  ),
  ReportFix(
    id: 'featured',
    impact: FixImpact.medium,
    points: 6,
    free: false,
    suggestions: ['career_fix_featured_s1', 'career_fix_featured_s2'],
  ),
  ReportFix(
    id: 'experience',
    impact: FixImpact.medium,
    points: 7,
    free: false,
    suggestions: ['career_fix_experience_s1', 'career_fix_experience_s2'],
  ),
  ReportFix(
    id: 'skills',
    impact: FixImpact.medium,
    points: 4,
    free: false,
    suggestions: ['career_fix_skills_s1', 'career_fix_skills_s2'],
  ),
  ReportFix(
    id: 'banner',
    impact: FixImpact.low,
    points: 3,
    free: false,
    suggestions: ['career_fix_banner_s1', 'career_fix_banner_s2'],
  ),
  ReportFix(
    id: 'link',
    impact: FixImpact.low,
    points: 2,
    free: false,
    suggestions: ['career_fix_link_s1', 'career_fix_link_s2'],
  ),
];

