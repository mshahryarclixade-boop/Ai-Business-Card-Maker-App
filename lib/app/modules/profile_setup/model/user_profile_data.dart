import 'dart:convert';
import 'dart:typed_data';

class UserProfileData {
  const UserProfileData({
    this.fullName = '',
    this.email = '',
    this.dialCode = '+92',
    this.phoneNumber = '',
    this.companyName = '',
    this.designation = '',
    this.website = '',
    this.logoBytes,
    this.logoName = '',
  });

  final String fullName;
  final String email;
  final String dialCode;
  final String phoneNumber;
  final String companyName;
  final String designation;
  final String website;
  final Uint8List? logoBytes;
  final String logoName;

  /// Country code + number, or empty if no number was entered.
  String get phone => phoneNumber.isEmpty ? '' : '$dialCode $phoneNumber';

  bool get hasLogo => logoBytes != null && logoBytes!.isNotEmpty;

  /// Text fields for the AI prompt. Empty values are left out.
  /// The logo is passed separately via [logoBytes].
  Map<String, String> toPromptMap() => {
    if (fullName.isNotEmpty) 'fullName': fullName,
    if (email.isNotEmpty) 'email': email,
    if (phone.isNotEmpty) 'phone': phone,
    if (companyName.isNotEmpty) 'companyName': companyName,
    if (designation.isNotEmpty) 'designation': designation,
    if (website.isNotEmpty) 'website': website,
  };

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'dialCode': dialCode,
    'phoneNumber': phoneNumber,
    'companyName': companyName,
    'designation': designation,
    'website': website,
    'logoName': logoName,
    'logoBase64': logoBytes == null ? null : base64Encode(logoBytes!),
  };

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    final logo = json['logoBase64'] as String?;
    return UserProfileData(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dialCode: json['dialCode'] as String? ?? '+92',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      website: json['website'] as String? ?? '',
      logoName: json['logoName'] as String? ?? '',
      logoBytes: logo == null ? null : base64Decode(logo),
    );
  }
}