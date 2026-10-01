/// Holds the fields collected on the "Custom QR Code" form
/// (Personal Info, Professional, Website, Social Links, Location).
class SocialLink {
  final String platform; // e.g. "LinkedIn", "Instagram", "Github"
  final String url;

  const SocialLink({required this.platform, required this.url});
}

class QrProfileData {
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final String companyName;
  final String designation;
  final String websiteUrl;
  final List<SocialLink> socialLinks;
  final String country;
  final String city;

  const QrProfileData({
    required this.fullName,
    this.phoneNumber = '',
    this.emailAddress = '',
    this.companyName = '',
    this.designation = '',
    this.websiteUrl = '',
    this.socialLinks = const [],
    this.country = '',
    this.city = '',
  });

  bool get isValid => fullName.trim().isNotEmpty;
}