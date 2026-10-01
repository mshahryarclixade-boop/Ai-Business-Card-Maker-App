class ProfileModel {
  String firstName;
  String lastName;
  String tagline;

  String companyName;
  String jobTitle;
  String companyWebsite;

  String email;
  String phone;
  String location;

  List<String> socialLinks;

  String? frontImagePath;
  String? coverImagePath;

  ProfileModel({
    this.firstName = '',
    this.lastName = '',
    this.tagline = '',
    this.companyName = '',
    this.jobTitle = '',
    this.companyWebsite = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.socialLinks = const [],
    this.frontImagePath,
    this.coverImagePath,
  });

  bool get isComplete {
    return firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        tagline.trim().isNotEmpty &&
        companyName.trim().isNotEmpty &&
        jobTitle.trim().isNotEmpty &&
        companyWebsite.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        location.trim().isNotEmpty;
  }

  String get fullName => '$firstName $lastName'.trim();

  // ⬇️ NEW: convert to/from a plain Map so GetStorage can persist it.
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'tagline': tagline,
      'companyName': companyName,
      'jobTitle': jobTitle,
      'companyWebsite': companyWebsite,
      'email': email,
      'phone': phone,
      'location': location,
      'socialLinks': socialLinks,
      'frontImagePath': frontImagePath,
      'coverImagePath': coverImagePath,
    };
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      tagline: json['tagline'] ?? '',
      companyName: json['companyName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      companyWebsite: json['companyWebsite'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      socialLinks: (json['socialLinks'] as List?)?.map((e) => e.toString()).toList() ?? [],
      frontImagePath: json['frontImagePath'],
      coverImagePath: json['coverImagePath'],
    );
  }
}