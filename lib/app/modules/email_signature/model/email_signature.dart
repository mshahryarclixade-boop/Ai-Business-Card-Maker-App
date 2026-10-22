import 'dart:convert';
import 'dart:typed_data';

enum SignatureStyle { classic, compact, banner }

/// One saved email signature.
class EmailSignature {
  const EmailSignature({
    required this.id,
    this.style = SignatureStyle.classic,
    this.fullName = '',
    this.jobTitle = '',
    this.company = '',
    this.phone = '',
    this.website = '',
    this.photo,
    this.logo,
    this.showQr = false,
    this.showBookCall = false,
  });

  final String id;
  final SignatureStyle style;
  final String fullName;
  final String jobTitle;
  final String company;
  final String phone;
  final String website;

  /// Picked images (null = the default avatar / the company-initial badge).
  final Uint8List? photo;
  final Uint8List? logo;

  final bool showQr;

  /// Pro: a "Book a 15-min call" button that opens [website].
  final bool showBookCall;

  /// "Product Designer · Northwind Studio" (empty parts left out).
  String get roleLine =>
      [jobTitle, company].where((s) => s.trim().isNotEmpty).join(' · ');

  /// "+92 300 1234567 · northwind.co" (empty parts left out).
  String get contactLine =>
      [phone, website].where((s) => s.trim().isNotEmpty).join(' · ');

  /// Link behind the QR code and the book-a-call button.
  String get link {
    final w = website.trim();
    if (w.isEmpty) return '';
    return w.startsWith('http') ? w : 'https://$w';
  }

  /// What the QR code holds: a contact card (vCard) people can scan to save.
  String get qrData => [
    'BEGIN:VCARD',
    'VERSION:3.0',
    'FN:${fullName.trim()}',
    if (company.trim().isNotEmpty) 'ORG:${company.trim()}',
    if (jobTitle.trim().isNotEmpty) 'TITLE:${jobTitle.trim()}',
    if (phone.trim().isNotEmpty) 'TEL:${phone.trim()}',
    if (link.isNotEmpty) 'URL:$link',
    'END:VCARD',
  ].join('\n');

  /// The signature as plain text (what "Copy signature" puts on the
  /// clipboard). [madeWith] is the free plan's footer line, or null.
  String toPlainText({String? madeWith, String? bookCall}) {
    final lines = [
      fullName.trim(),
      roleLine,
      contactLine,
      if (showBookCall && bookCall != null && link.isNotEmpty)
        '$bookCall: $link',
    ].where((l) => l.isNotEmpty).toList();
    if (madeWith != null) {
      lines
        ..add('')
        ..add(madeWith);
    }
    return lines.join('\n');
  }

  EmailSignature copyWith({
    SignatureStyle? style,
    String? fullName,
    String? jobTitle,
    String? company,
    String? phone,
    String? website,
    Uint8List? photo,
    Uint8List? logo,
    bool clearPhoto = false,
    bool clearLogo = false,
    bool? showQr,
    bool? showBookCall,
  }) => EmailSignature(
    id: id,
    style: style ?? this.style,
    fullName: fullName ?? this.fullName,
    jobTitle: jobTitle ?? this.jobTitle,
    company: company ?? this.company,
    phone: phone ?? this.phone,
    website: website ?? this.website,
    photo: clearPhoto ? null : (photo ?? this.photo),
    logo: clearLogo ? null : (logo ?? this.logo),
    showQr: showQr ?? this.showQr,
    showBookCall: showBookCall ?? this.showBookCall,
  );

  /// Same content (ignoring the id): used to tell whether the user edited.
  bool sameContentAs(EmailSignature o) =>
      style == o.style &&
      fullName == o.fullName &&
      jobTitle == o.jobTitle &&
      company == o.company &&
      phone == o.phone &&
      website == o.website &&
      showQr == o.showQr &&
      showBookCall == o.showBookCall &&
      _same(photo, o.photo) &&
      _same(logo, o.logo);

  static bool _same(Uint8List? a, Uint8List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'style': style.name,
    'fullName': fullName,
    'jobTitle': jobTitle,
    'company': company,
    'phone': phone,
    'website': website,
    'photo': photo == null ? null : base64Encode(photo!),
    'logo': logo == null ? null : base64Encode(logo!),
    'showQr': showQr,
    'showBookCall': showBookCall,
  };

  factory EmailSignature.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] as String?) ?? '';
    Uint8List? img(String k) {
      final v = j[k];
      return v is String && v.isNotEmpty ? base64Decode(v) : null;
    }

    return EmailSignature(
      id: s('id'),
      style: SignatureStyle.values.firstWhere(
        (e) => e.name == j['style'],
        orElse: () => SignatureStyle.classic,
      ),
      fullName: s('fullName'),
      jobTitle: s('jobTitle'),
      company: s('company'),
      phone: s('phone'),
      website: s('website'),
      photo: img('photo'),
      logo: img('logo'),
      showQr: j['showQr'] == true,
      showBookCall: j['showBookCall'] == true,
    );
  }
}
