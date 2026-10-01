import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/contact_model.dart';

class ContactExportService {
  ContactExportService._();

  /// false = share without photo (works everywhere, incl. WhatsApp).
  /// true  = embed the photo (fine for apps other than WhatsApp).
  static const bool embedPhotoInShare = false;

  // ---------------------------------------------------------------------
  // SAVE TO DEVICE
  // ---------------------------------------------------------------------

  static Future<void> saveToDevice(ContactModel c) async {
    try {
      final granted =
      await fc.FlutterContacts.requestPermission(readonly: false);
      if (!granted) {
        _snack('Permission needed',
            'Allow contacts access to save this contact.');
        return;
      }

      final photo = await _loadPhoto(c.imagePath);

      final first = c.firstName.trim().isNotEmpty || c.lastName.trim().isNotEmpty
          ? c.firstName.trim()
          : c.companyName.trim();

      final contact = fc.Contact(
        name: fc.Name(first: first, last: c.lastName.trim()),
        photo: photo?.$1,
        phones: _clean([c.phone]).map((p) => fc.Phone(p)).toList(),
        emails: [
          ..._clean([c.email]).map((e) => fc.Email(e)),
          ..._clean([c.companyEmail])
              .map((e) => fc.Email(e, label: fc.EmailLabel.work)),
        ],
        organizations: (c.companyName.trim().isNotEmpty ||
            c.jobTitle.trim().isNotEmpty)
            ? [
          fc.Organization(
            company: c.companyName.trim(),
            title: c.jobTitle.trim(),
          ),
        ]
            : [],
        websites: _urls(c).map((u) => fc.Website(u)).toList(),
        addresses: _clean([c.companyAddress])
            .map((a) => fc.Address(a, label: fc.AddressLabel.work))
            .toList(),
        notes: _clean([c.notes]).map((n) => fc.Note(n)).toList(),
      );

      // Save every detail (incl. photo) straight into the address book.
      final saved = await fc.FlutterContacts.insertContact(contact);

      _snack('Saved', 'Contact saved to your phone.');

      // Then open the saved contact in the phone's own Contacts app.
      // (Use openExternalEdit instead if you want it to open in edit mode.)
      try {
        await fc.FlutterContacts.openExternalView(saved.id);
      } catch (e) {
        debugPrint('CONTACT OPEN VIEW failed: $e');
      }
    } catch (e, st) {
      debugPrint('CONTACT SAVE ERROR: $e');
      debugPrint('$st');
      _snack('Could not save', 'Something went wrong while saving the contact.');
    }
  }

  // ---------------------------------------------------------------------
  // SHARE AS A CONTACT (.vcf)
  // ---------------------------------------------------------------------

  static Future<void> share(ContactModel c) async {
    try {
      final vcf = await _buildVCard(c);

      final dir = await getTemporaryDirectory();
      final fileName = '${_safeFileName(c)}.vcf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(vcf, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/x-vcard', name: fileName)],
        subject: c.fullName.isNotEmpty ? c.fullName : c.companyName,
      );
    } catch (e, st) {
      debugPrint('CONTACT SHARE ERROR: $e');
      debugPrint('$st');
      _snack('Could not share', 'Something went wrong while sharing the contact.');
    }
  }

  static Future<String> _buildVCard(ContactModel c) async {
    final displayName = c.fullName.isNotEmpty ? c.fullName : c.companyName;

    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'N:${_esc(c.lastName.trim())};${_esc(c.firstName.trim())};;;',
      'FN:${_esc(displayName)}',
    ];

    if (c.companyName.trim().isNotEmpty) {
      lines.add('ORG:${_esc(c.companyName.trim())}');
    }
    if (c.jobTitle.trim().isNotEmpty) {
      lines.add('TITLE:${_esc(c.jobTitle.trim())}');
    }
    for (final p in _clean([c.phone])) {
      lines.add('TEL;TYPE=CELL:${_esc(p)}');
    }
    for (final e in _clean([c.email])) {
      lines.add('EMAIL;TYPE=INTERNET:${_esc(e)}');
    }
    for (final e in _clean([c.companyEmail])) {
      lines.add('EMAIL;TYPE=INTERNET,WORK:${_esc(e)}');
    }
    for (final u in _urls(c)) {
      lines.add('URL:$u');
    }
    for (final a in _clean([c.companyAddress])) {
      lines.add('ADR;TYPE=WORK:;;${_esc(a)};;;;');
    }
    if (c.notes.trim().isNotEmpty) {
      lines.add('NOTE:${_esc(c.notes.trim())}');
    }

    final photo = embedPhotoInShare ? await _loadPhoto(c.imagePath) : null;
    if (photo != null) {
      lines.add('PHOTO;ENCODING=b;TYPE=${photo.$2}:${base64Encode(photo.$1)}');
    }

    lines.add('END:VCARD');

    // vCard lines are CRLF separated and folded at 75 characters.
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// Non-empty, trimmed values only.
  static List<String> _clean(List<String> values) =>
      values.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();

  /// Every link the contact has (website, linkedin, company linkedin, custom).
  static List<String> _urls(ContactModel c) => _clean([
    c.website,
    c.linkedin,
    c.companyLinkedin,
    ...c.customLinks,
  ]);

  /// Escapes text values for vCard 3.0.
  static String _esc(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('\r\n', '\\n')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');

  /// Folds one vCard line to max 75 chars (continuation lines start with a space).
  static String _fold(String line) {
    if (line.length <= 75) return line;
    final buf = StringBuffer(line.substring(0, 75));
    var i = 75;
    while (i < line.length) {
      final end = (i + 74) > line.length ? line.length : i + 74;
      buf.write('\r\n ${line.substring(i, end)}');
      i = end;
    }
    return buf.toString();
  }

  static String _safeFileName(ContactModel c) {
    final base = (c.fullName.isNotEmpty ? c.fullName : c.companyName).trim();
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    return cleaned.isEmpty ? 'contact' : cleaned.replaceAll(' ', '_');
  }

  /// Loads the contact photo as a small JPEG (max 400px wide).
  /// JPEG is what phones' vCard importers handle most reliably; PNG or huge
  /// photos are what made the shared vCard "not supported".
  /// Returns (bytes, vCard type) or null if there is no usable photo.
  static Future<(Uint8List, String)?> _loadPhoto(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsBytes();
      final jpg = await compute(_toSmallJpeg, raw);
      if (jpg != null) return (jpg, 'JPEG');
    } catch (e) {
      debugPrint('CONTACT PHOTO convert failed, skipping photo: $e');
    }
    return null;
  }

  static void _snack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
  }
}

/// Runs in a background isolate: decode, fix rotation, shrink, re-encode as JPEG.
Uint8List? _toSmallJpeg(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return null;
  final oriented = img.bakeOrientation(decoded);
  final resized =
  oriented.width > 400 ? img.copyResize(oriented, width: 400) : oriented;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}