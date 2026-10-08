import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../profile_setup/service/profile_store.dart';
import '../model/contact_model.dart';

/// Opens the phone's messaging and mail apps with an editable draft.
class ContactFollowUpService {
  ContactFollowUpService._();

  static String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  /// A phone number that SMS can use, or null.
  static String? smsNumber(ContactModel c) {
    final p = c.phone.trim();
    if (_digits(p).length < 5) return null;
    return p.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  /// WhatsApp needs the full international number, so a number without a
  /// country code is not offered.
  static String? whatsappNumber(ContactModel c) {
    var p = c.phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('00')) p = '+${p.substring(2)}';
    if (!p.startsWith('+')) return null;
    final d = _digits(p);
    return d.length >= 8 ? d : null;
  }

  /// The contact's email, falling back to the company email.
  static String? email(ContactModel c) {
    final e =
    c.email.trim().isNotEmpty ? c.email.trim() : c.companyEmail.trim();
    return e.contains('@') ? e : null;
  }

  /// A short, friendly starting text. The user edits it before sending.
  static String draft(ContactModel c) {
    final to = c.firstName.trim();
    final me = ProfileStore.to.profile.value.fullName.trim();
    final hello = to.isEmpty ? 'Hi,' : 'Hi $to,';
    final bye = me.isEmpty ? '' : '\n\nBest regards,\n$me';
    return '$hello\n\nIt was great meeting you. '
        'I would love to stay in touch.$bye';
  }

  static Future<void> sendSms(ContactModel c) async {
    final number = smsNumber(c);
    if (number == null) return;
    final sep = Platform.isIOS ? '&' : '?';
    await _open(
      Uri.parse('sms:$number${sep}body=${Uri.encodeComponent(draft(c))}'),
    );
  }

  static Future<void> sendWhatsApp(ContactModel c) async {
    final number = whatsappNumber(c);
    if (number == null) return;
    await _open(
      Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(draft(c))}'),
    );
  }

  static Future<void> sendEmail(ContactModel c) async {
    final address = email(c);
    if (address == null) return;
    final subject = Uri.encodeComponent('Nice to meet you');
    final body = Uri.encodeComponent(draft(c));
    await _open(Uri.parse('mailto:$address?subject=$subject&body=$body'));
  }

  static Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _fail();
    } catch (_) {
      _fail();
    }
  }

  static void _fail() {
    Get.snackbar(
      'Could not open',
      'No app was found for this action.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
  }
}