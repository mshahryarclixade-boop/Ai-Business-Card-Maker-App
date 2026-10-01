import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../model/scanned_contact_data.dart';

class CardScannerService {
  final TextRecognizer _textRecognizer =
  TextRecognizer(script: TextRecognitionScript.latin);

  static final RegExp _emailRegex =
  RegExp(r'[\w.\-+]+@[\w\-]+\.[\w.\-]+');

  static final RegExp _phoneRegex =
  RegExp(r'^\+?[\d\s().\-]{7,}$');

  static final RegExp _urlRegex = RegExp(
    r'((https?:\/\/)?(www\.)?[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}(\/\S*)?)',
    caseSensitive: false,
  );

  static const _jobTitleHints = [
    'manager', 'director', 'engineer', 'designer', 'developer', 'ceo', 'cto',
    'cfo', 'coo', 'founder', 'co-founder', 'president', 'consultant', 'lead',
    'head of', 'specialist', 'executive', 'officer', 'analyst', 'architect',
    'owner', 'partner', 'representative', 'coordinator', 'recruiter',
  ];

  static const _companyHints = [
    'inc', 'llc', 'ltd', 'co', 'corp', 'company', 'technologies', 'tech',
    'studio', 'group', 'solutions', 'systems', 'labs', 'agency', 'partners',
    'associates', 'enterprises',
  ];

  /// Runs OCR on a captured/picked card photo and extracts contact fields.
  Future<ScannedContactData> extractFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);

    final lines = <String>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) lines.add(text);
      }
    }

    return _parseFreeformLines(lines, imagePath: imagePath);
  }

  /// Decodes a scanned QR payload. Business-card QR codes are usually a
  /// vCard (`BEGIN:VCARD...`) or a MECARD string; anything else falls back
  /// to line-by-line heuristics, same as OCR text.
  ScannedContactData parseQrPayload(String raw) {
    final trimmed = raw.trim();

    if (RegExp(r'^BEGIN:VCARD', caseSensitive: false).hasMatch(trimmed)) {
      return _parseVCard(trimmed);
    }
    if (RegExp(r'^MECARD:', caseSensitive: false).hasMatch(trimmed)) {
      return _parseMeCard(trimmed);
    }

    final lines = trimmed
        .split(RegExp(r'[\n\r]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return _parseFreeformLines(lines, fromQrCode: true);
  }

  // -------------------------------------------------------------------
  // Freeform (OCR / plain-text QR) parsing
  // -------------------------------------------------------------------

  ScannedContactData _parseFreeformLines(
      List<String> rawLines, {
        String? imagePath,
        bool fromQrCode = false,
      }) {
    final lines = List<String>.from(rawLines);
    final used = <int>{};

    String? email;
    String? phone;
    String? website;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (email == null) {
        final match = _emailRegex.firstMatch(line);
        if (match != null) {
          email = match.group(0);
          used.add(i);
          continue;
        }
      }

      if (website == null && !line.contains('@')) {
        final match = _urlRegex.firstMatch(line);
        if (match != null) {
          website = _normalizeUrl(match.group(0)!);
          used.add(i);
          continue;
        }
      }

      if (phone == null) {
        final digitCount = line.replaceAll(RegExp(r'[^0-9]'), '').length;
        if (digitCount >= 7 && _phoneRegex.hasMatch(line.trim())) {
          phone = line.trim();
          used.add(i);
          continue;
        }
      }
    }

    final remaining = [
      for (var i = 0; i < lines.length; i++)
        if (!used.contains(i)) lines[i],
    ];

    String? jobTitle;
    for (final line in remaining) {
      final lower = line.toLowerCase();
      if (_jobTitleHints.any((hint) => lower.contains(hint))) {
        jobTitle = line;
        break;
      }
    }
    remaining.remove(jobTitle);

    String? company;
    for (final line in remaining) {
      final lower = line.toLowerCase();
      final words = lower.split(RegExp(r'\s+'));
      if (_companyHints.any((hint) => words.contains(hint) || lower.endsWith(hint))) {
        company = line;
        break;
      }
    }
    remaining.remove(company);

    // Name heuristic: the first short, digit-free remaining line — cards
    // almost always put the person's name before their title/company.
    String? name;
    for (final line in remaining) {
      final words = line.split(RegExp(r'\s+'));
      if (words.length <= 4 && !RegExp(r'\d').hasMatch(line)) {
        name = line;
        break;
      }
    }
    remaining.remove(name);

    // Still no company guess? Fall back to the longest leftover line.
    if (company == null && remaining.isNotEmpty) {
      remaining.sort((a, b) => b.length.compareTo(a.length));
      company = remaining.first;
    }

    var firstName = '';
    var lastName = '';
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return _build(
      firstName: firstName,
      lastName: lastName,
      companyName: company ?? '',
      jobTitle: jobTitle ?? '',
      email: email ?? '',
      phone: phone ?? '',
      website: website ?? '',
      imagePath: imagePath,
      fromQrCode: fromQrCode,
    );
  }

  // -------------------------------------------------------------------
  // Structured QR formats
  // -------------------------------------------------------------------

  ScannedContactData _parseVCard(String raw) {
    var firstName = '';
    var lastName = '';
    var company = '';
    var jobTitle = '';
    var email = '';
    var phone = '';
    var linkedin = '';
    var website = '';

    for (final rawLine in raw.split(RegExp(r'[\n\r]+'))) {
      final line = rawLine.trim();
      final sep = line.indexOf(':');
      if (sep == -1) continue;

      final key = line.substring(0, sep).split(';').first.toUpperCase();
      final value = line.substring(sep + 1).trim();
      if (value.isEmpty) continue;

      switch (key) {
        case 'N':
          final parts = value.split(';');
          lastName = parts.isNotEmpty ? parts[0].trim() : lastName;
          if (parts.length > 1 && parts[1].trim().isNotEmpty) {
            firstName = parts[1].trim();
          }
          break;
        case 'FN':
          if (firstName.isEmpty && lastName.isEmpty) {
            final parts = value.split(RegExp(r'\s+'));
            firstName = parts.first;
            lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }
          break;
        case 'ORG':
          company = value.split(';').first.trim();
          break;
        case 'TITLE':
          jobTitle = value;
          break;
        case 'EMAIL':
          if (email.isEmpty) email = value;
          break;
        case 'TEL':
          if (phone.isEmpty) phone = value;
          break;
        case 'URL':
          if (value.toLowerCase().contains('linkedin.com')) {
            linkedin = value;
          } else if (website.isEmpty) {
            website = value;
          }
          break;
      }
    }

    return _build(
      firstName: firstName,
      lastName: lastName,
      companyName: company,
      jobTitle: jobTitle,
      email: email,
      phone: phone,
      linkedin: linkedin,
      website: website,
      fromQrCode: true,
    );
  }

  ScannedContactData _parseMeCard(String raw) {
    final body = raw.replaceFirst(RegExp(r'^MECARD:', caseSensitive: false), '');
    var firstName = '';
    var lastName = '';
    var company = '';
    var phone = '';
    var email = '';
    var website = '';

    for (final field in body.split(';')) {
      final sep = field.indexOf(':');
      if (sep == -1) continue;

      final key = field.substring(0, sep).toUpperCase();
      final value = field.substring(sep + 1).trim();
      if (value.isEmpty) continue;

      switch (key) {
        case 'N':
          final parts = value.split(',');
          lastName = parts.isNotEmpty ? parts[0].trim() : lastName;
          if (parts.length > 1) firstName = parts[1].trim();
          break;
        case 'ORG':
          company = value;
          break;
        case 'TEL':
          phone = value;
          break;
        case 'EMAIL':
          email = value;
          break;
        case 'URL':
          website = value;
          break;
      }
    }

    return _build(
      firstName: firstName,
      lastName: lastName,
      companyName: company,
      jobTitle: '',
      email: email,
      phone: phone,
      website: website,
      fromQrCode: true,
    );
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------

  ScannedContactData _build({
    required String firstName,
    required String lastName,
    required String companyName,
    required String jobTitle,
    required String email,
    required String phone,
    String linkedin = '',
    required String website,
    String? imagePath,
    bool fromQrCode = false,
  }) {
    final warnings = <String>[];
    if (firstName.trim().isEmpty) warnings.add('name');
    if (companyName.trim().isEmpty) warnings.add('company');

    return ScannedContactData(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      companyName: companyName.trim(),
      jobTitle: jobTitle.trim(),
      email: email.trim(),
      phone: phone.trim(),
      linkedin: linkedin.trim(),
      website: website.trim(),
      imagePath: imagePath,
      warnings: warnings,
      fromQrCode: fromQrCode,
    );
  }

  String _normalizeUrl(String raw) {
    var url = raw.trim();
    if (!url.toLowerCase().startsWith('http')) url = 'https://$url';
    return url;
  }

  void dispose() => _textRecognizer.close();
}
