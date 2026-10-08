import 'dart:ui' show Rect;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../model/scanned_contact_data.dart';

class _Ln {
  const _Ln(this.text, [this.box]);

  final String text;
  final Rect? box;
}

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

  // Taglines like "A project of X Group" are not the company name.
  static final RegExp _taglineRegex = RegExp(
    r'^(a\s+)?(project|unit|division|subsidiary|brand|member)\s+of\b',
    caseSensitive: false,
  );

  // Words that never appear in a person's name.
  static final RegExp _notNameWords = RegExp(
    r'\b(project|group|limited|ltd|private|pvt|college|university|institute|'
    r'company|companies|solutions|technologies|www|email|phone|mobile|tel|'
    r'fax|address|scan)\b',
    caseSensitive: false,
  );

  static const _jobTitleHints = [
    'manager', 'director', 'engineer', 'designer', 'developer', 'ceo', 'cto',
    'cfo', 'coo', 'founder', 'co-founder', 'president', 'consultant', 'lead',
    'head of', 'specialist', 'executive', 'officer', 'analyst', 'architect',
    'owner', 'partner', 'representative', 'coordinator', 'recruiter',
    'administration', 'administrator', 'admin', 'assistant', 'supervisor',
    'secretary', 'accountant', 'sales', 'marketing', 'teacher', 'professor',
    'lecturer', 'instructor', 'principal', 'dean', 'chairman', 'chairperson',
    'advisor', 'trainer', 'receptionist', 'operations', 'intern', 'technician',
  ];

  static const _companyHints = [
    'inc', 'llc', 'ltd', 'co', 'corp', 'company', 'technologies', 'tech',
    'studio', 'group', 'solutions', 'systems', 'labs', 'agency', 'partners',
    'associates', 'enterprises', 'limited', 'pvt', 'private', 'college',
    'university', 'institute', 'academy', 'school',
  ];

  /// Runs OCR on a captured/picked card photo and extracts contact fields.
  Future<ScannedContactData> extractFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);

    final lines = <_Ln>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) lines.add(_Ln(text, line.boundingBox));
      }
    }

    // Read top-to-bottom so the result does not depend on how ML Kit
    // happens to group the text into blocks.
    lines.sort((a, b) {
      final byTop = a.box!.top.compareTo(b.box!.top);
      return byTop != 0 ? byTop : a.box!.left.compareTo(b.box!.left);
    });

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
        .map((e) => _Ln(e))
        .toList();

    return _parseFreeformLines(lines, fromQrCode: true);
  }

  // -------------------------------------------------------------------
  // Freeform (OCR / plain-text QR) parsing
  // -------------------------------------------------------------------

  ScannedContactData _parseFreeformLines(
      List<_Ln> lines, {
        String? imagePath,
        bool fromQrCode = false,
      }) {
    final used = <int>{};

    String? email;
    final websites = <String>[];
    final phones = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].text;

      if (email == null) {
        final match = _emailRegex.firstMatch(line);
        if (match != null) {
          email = match.group(0);
          used.add(i);
          continue;
        }
      }

      if (!line.contains('@')) {
        final match = _urlRegex.firstMatch(line);
        if (match != null) {
          websites.add(_normalizeUrl(match.group(0)!));
          used.add(i);
          continue;
        }
      }

      final digitCount = line.replaceAll(RegExp(r'[^0-9]'), '').length;
      if (digitCount >= 7 && _phoneRegex.hasMatch(line.trim())) {
        phones.add(line.trim());
        used.add(i);
        continue;
      }
    }

    // Several websites (e.g. background text)? Prefer the one matching the
    // email's domain.
    String? website = websites.isEmpty ? null : websites.first;
    if (email != null && websites.length > 1) {
      final domain = email.split('@').last.toLowerCase();
      for (final w in websites) {
        if (w.toLowerCase().contains(domain)) {
          website = w;
          break;
        }
      }
    }

    final phone = phones.isEmpty ? null : _repairCountryCode(phones);

    final remaining = <_Ln>[
      for (var i = 0; i < lines.length; i++)
        if (!used.contains(i)) lines[i],
    ];

    // "A project of ..." taglines are never name / title / company.
    remaining.removeWhere((l) => _taglineRegex.hasMatch(l.text));

    // Job title: a line containing a known title word.
    _Ln? jobLn;
    for (final l in remaining) {
      if (RegExp(r'\d').hasMatch(l.text)) continue;
      if (_jobTitleHints.any((hint) => _hasWord(l.text, hint))) {
        jobLn = l;
        break;
      }
    }
    remaining.remove(jobLn);

    // Company: a line containing a known company word.
    _Ln? companyLn;
    for (final l in remaining) {
      final lower = l.text.toLowerCase();
      final words = lower.split(RegExp(r'\s+'));
      if (_companyHints.any((hint) => words.contains(hint) || lower.endsWith(hint))) {
        companyLn = l;
        break;
      }
    }
    remaining.remove(companyLn);

    // Name: best-scoring line (see _nameScore). No guess is better than a
    // wrong one - the review screen shows a warning when it is empty.
    var maxHeight = 0.0;
    for (final l in lines) {
      final h = l.box?.height ?? 0;
      if (h > maxHeight) maxHeight = h;
    }

    _Ln? nameLn;
    var bestScore = 0.0;
    for (final l in remaining) {
      final score = _nameScore(l, maxHeight);
      if (score > bestScore) {
        bestScore = score;
        nameLn = l;
      }
    }
    remaining.remove(nameLn);

    // No known title word? Take the line right below the name.
    if (jobLn == null && nameLn?.box != null) {
      jobLn = _lineBelow(nameLn!, remaining);
      remaining.remove(jobLn);
    }

    // Still no company guess? Fall back to the longest leftover line.
    String? company = companyLn?.text;
    if (company == null && remaining.isNotEmpty) {
      remaining.sort((a, b) => b.text.length.compareTo(a.text.length));
      company = remaining.first.text;
    }

    var firstName = '';
    var lastName = '';
    final name = nameLn?.text;
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      firstName = parts.first;
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return _build(
      firstName: firstName,
      lastName: lastName,
      companyName: company ?? '',
      jobTitle: jobLn?.text ?? '',
      email: email ?? '',
      phone: phone ?? '',
      website: website ?? '',
      imagePath: imagePath,
      fromQrCode: fromQrCode,
    );
  }

  /// Whole-word match, so "cto" does not match inside "Victor".
  bool _hasWord(String text, String word) {
    return RegExp(
      '\\b${RegExp.escape(word)}\\b',
      caseSensitive: false,
    ).hasMatch(text);
  }

  /// Scores how much a line looks like a person's name. -1 = not a name.
  double _nameScore(_Ln l, double maxHeight) {
    final text = l.text.trim();

    if (RegExp(r'[\d@/:]').hasMatch(text)) return -1;
    if (!RegExp(r"^[A-Za-z][A-Za-z.\-' ]*$").hasMatch(text)) return -1;
    if (_notNameWords.hasMatch(text)) return -1;

    final words = text.split(RegExp(r'\s+'));
    if (words.length > 4) return -1;

    // Names on cards are UPPERCASE or Title Case. "lace kar dn" is noise.
    final isUpper = text == text.toUpperCase();
    final isTitle = words.every((w) => RegExp(r'^[A-Z]').hasMatch(w));
    if (!isUpper && !isTitle) return -1;

    // One-letter words are only fine as initials ("J." / "A.").
    for (final w in words) {
      if (w.replaceAll('.', '').length < 2 && !w.endsWith('.')) return -1;
    }

    var score = 1.0;
    if (words.length >= 2) score += 3;
    if (words.length <= 3) score += 1;
    if (l.box != null && maxHeight > 0) {
      score += 2 * (l.box!.height / maxHeight);
    }
    return score;
  }

  /// The closest line directly under [anchor] (used for the job title).
  _Ln? _lineBelow(_Ln anchor, List<_Ln> candidates) {
    final a = anchor.box!;
    _Ln? best;
    var bestGap = double.infinity;

    for (final c in candidates) {
      final b = c.box;
      if (b == null) continue;
      if (RegExp(r'\d').hasMatch(c.text)) continue;
      if (c.text.split(RegExp(r'\s+')).length > 5) continue;

      final gap = b.top - a.bottom;
      if (gap < -a.height * 0.3 || gap > a.height * 2.5) continue;
      if ((b.left - a.left).abs() > a.height * 3) continue;

      if (gap < bestGap) {
        bestGap = gap;
        best = c;
      }
    }
    return best;
  }

  /// OCR sometimes misreads "+92" as a stray 3-digit group (e.g. "495").
  /// If another number on the same card has a clean "+CC", reuse its code.
  /// Narrow guess: only when the first number has no "+", starts with a
  /// 3-digit group, and has 12+ digits.
  String _repairCountryCode(List<String> phones) {
    final first = phones.first;
    if (first.startsWith('+') || first.startsWith('0')) return first;

    final digits = first.replaceAll(RegExp(r'[^0-9]'), '');
    final parts = first.split(RegExp(r'\s+'));
    if (digits.length < 12 || parts.length < 2) return first;
    if (!RegExp(r'^[1-9]\d{2}$').hasMatch(parts.first)) return first;

    for (final other in phones.skip(1)) {
      final m = RegExp(r'^\+(\d{1,3})\b').firstMatch(other.trim());
      if (m != null) {
        return '+${m.group(1)} ${parts.skip(1).join(' ')}';
      }
    }
    return first;
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