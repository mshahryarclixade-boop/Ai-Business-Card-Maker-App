import 'qr_profile_data.dart';

String buildVCard(QrProfileData profile) {
  final buffer = StringBuffer()
    ..writeln('BEGIN:VCARD')
    ..writeln('VERSION:3.0')
    ..writeln('FN:${_escape(profile.fullName)}');

  if (profile.companyName.isNotEmpty) {
    buffer.writeln('ORG:${_escape(profile.companyName)}');
  }
  if (profile.designation.isNotEmpty) {
    buffer.writeln('TITLE:${_escape(profile.designation)}');
  }
  if (profile.phoneNumber.isNotEmpty) {
    buffer.writeln('TEL;TYPE=CELL:${_escape(profile.phoneNumber)}');
  }
  if (profile.emailAddress.isNotEmpty) {
    buffer.writeln('EMAIL:${_escape(profile.emailAddress)}');
  }
  if (profile.websiteUrl.isNotEmpty) {
    buffer.writeln('URL:${_escape(profile.websiteUrl)}');
  }
  if (profile.country.isNotEmpty || profile.city.isNotEmpty) {
    // ADR;TYPE=WORK:PO;Extended;Street;City;Region;PostalCode;Country
    buffer.writeln(
      'ADR;TYPE=WORK:;;;${_escape(profile.city)};;;${_escape(profile.country)}',
    );
  }
  for (var i = 0; i < profile.socialLinks.length; i++) {
    final link = profile.socialLinks[i];
    if (link.url.trim().isEmpty) continue;
    buffer
      ..writeln('item${i + 1}.URL:${_escape(link.url)}')
      ..writeln('item${i + 1}.X-ABLabel:${_escape(link.platform)}');
  }

  buffer.writeln('END:VCARD');
  return buffer.toString();
}

String _escape(String value) =>
    value.replaceAll(',', '\\,').replaceAll(';', '\\;').trim();