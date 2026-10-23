import 'qr_profile_data.dart';
import 'qr_style.dart';

/// One saved QR code: what it holds (the form the user filled in), the style
/// they picked, and when it was made.
class QrEntry {
  const QrEntry({
    required this.id,
    required this.form,
    required this.styleId,
    required this.createdAt,
  });

  final String id;

  /// The "Custom QR code" form as saved (see [QrProfileData.fromForm]).
  final Map<String, dynamic> form;
  final String styleId;
  final DateTime createdAt;

  QrStyle get style => QrStyles.byId(styleId);

  QrProfileData get profileData =>
      QrProfileData.fromForm(form) ?? const QrProfileData(fullName: '');

  String get title => profileData.fullName;

  QrEntry copyWith({Map<String, dynamic>? form, String? styleId}) => QrEntry(
    id: id,
    form: form ?? this.form,
    styleId: styleId ?? this.styleId,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'form': form,
    'style': styleId,
    'createdAt': createdAt.toIso8601String(),
  };

  static QrEntry? fromJson(Map<String, dynamic> j) {
    final form = j['form'];
    final id = j['id'];
    if (form is! Map || id is! String) return null;
    return QrEntry(
      id: id,
      form: Map<String, dynamic>.from(form),
      styleId: (j['style'] as String?) ?? QrStyles.classic.id,
      createdAt:
          DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
