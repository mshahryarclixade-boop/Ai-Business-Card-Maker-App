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

  /// Reads the saved "Custom QR code" form (the map the form screen stores:
  /// fullName, phone, email, company, designation, website, country, city and
  /// links). Null if it has no name.
  static QrProfileData? fromForm(Map<String, dynamic> m) {
    String str(dynamic v) => v is String ? v : '';
    final links = <SocialLink>[];
    for (final item in (m['links'] as List?) ?? const []) {
      if (item is Map) {
        links.add(
          SocialLink(platform: str(item['platform']), url: str(item['url'])),
        );
      }
    }
    final data = QrProfileData(
      fullName: str(m['fullName']),
      phoneNumber: str(m['phone']),
      emailAddress: str(m['email']),
      companyName: str(m['company']),
      designation: str(m['designation']),
      websiteUrl: str(m['website']),
      country: str(m['country']),
      city: str(m['city']),
      socialLinks: links,
    );
    return data.isValid ? data : null;
  }
}
