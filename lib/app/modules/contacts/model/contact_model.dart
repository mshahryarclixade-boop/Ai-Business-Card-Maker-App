class ContactModel {
  final String id;
  String firstName;
  String lastName;
  String companyName;
  String jobTitle;
  String email;
  String phone;
  String linkedin;
  String website;
  String notes;
  List<String> customLinks;
  String companyEmail;
  String companyLinkedin;
  String companyAddress;
  String? imagePath; // local file path, persisted on device
  final DateTime createdAt;

  ContactModel({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.companyName = '',
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.linkedin = '',
    this.website = '',
    this.notes = '',
    List<String>? customLinks,
    this.companyEmail = '',
    this.companyLinkedin = '',
    this.companyAddress = '',
    this.imagePath,
    DateTime? createdAt,
  })  : customLinks = customLinks ?? <String>[],
        createdAt = createdAt ?? DateTime.now();

  String get fullName =>
      [firstName, lastName].where((e) => e.trim().isNotEmpty).join(' ').trim();

  /// "Job Title • Company" line used under the name on cards / detail view.
  String get subtitle {
    final parts = [jobTitle, companyName].where((e) => e.trim().isNotEmpty).toList();
    return parts.join(' • ');
  }

  String get initials {
    final f = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final l = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    final result = (f + l).toUpperCase();
    return result.isNotEmpty ? result : '?';
  }

  ContactModel copyWith({
    String? firstName,
    String? lastName,
    String? companyName,
    String? jobTitle,
    String? email,
    String? phone,
    String? linkedin,
    String? website,
    String? notes,
    List<String>? customLinks,
    String? companyEmail,
    String? companyLinkedin,
    String? companyAddress,
    String? imagePath,
  }) {
    return ContactModel(
      id: id,
      createdAt: createdAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedin: linkedin ?? this.linkedin,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      customLinks: customLinks ?? List<String>.from(this.customLinks),
      companyEmail: companyEmail ?? this.companyEmail,
      companyLinkedin: companyLinkedin ?? this.companyLinkedin,
      companyAddress: companyAddress ?? this.companyAddress,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      companyName: json['companyName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      linkedin: json['linkedin'] ?? '',
      website: json['website'] ?? '',
      notes: json['notes'] ?? '',
      customLinks: (json['customLinks'] as List?)?.map((e) => e.toString()).toList() ?? [],
      companyEmail: json['companyEmail'] ?? '',
      companyLinkedin: json['companyLinkedin'] ?? '',
      companyAddress: json['companyAddress'] ?? '',
      imagePath: json['imagePath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'companyName': companyName,
    'jobTitle': jobTitle,
    'email': email,
    'phone': phone,
    'linkedin': linkedin,
    'website': website,
    'notes': notes,
    'customLinks': customLinks,
    'companyEmail': companyEmail,
    'companyLinkedin': companyLinkedin,
    'companyAddress': companyAddress,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
  };
}