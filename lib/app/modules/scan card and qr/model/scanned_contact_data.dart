class ScannedContactData {
  final String firstName;
  final String lastName;
  final String companyName;
  final String jobTitle;
  final String email;
  final String phone;
  final String linkedin;
  final String website;

  final String? imagePath;

  final List<String> warnings;

  final bool fromQrCode;

  const ScannedContactData({
    this.firstName = '',
    this.lastName = '',
    this.companyName = '',
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.linkedin = '',
    this.website = '',
    this.imagePath,
    this.warnings = const [],
    this.fromQrCode = false,
  });

  bool get isMissingName => warnings.contains('name');

  bool get isMissingCompany => warnings.contains('company');

  bool get hasWarnings => warnings.isNotEmpty;

  String get fullName =>
      [firstName, lastName].where((e) => e.trim().isNotEmpty).join(' ').trim();

  String get subtitle {
    final parts = [jobTitle, companyName].where((e) => e.trim().isNotEmpty).toList();
    return parts.join(' • ');
  }
}
