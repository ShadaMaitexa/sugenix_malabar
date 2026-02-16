class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final List<String> emergencyContacts;
  final Map<String, dynamic> medicalHistory;
  final List<String> allergies;
  final String preferredLanguage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.emergencyContacts = const [],
    this.medicalHistory = const {},
    this.allergies = const [],
    this.preferredLanguage = 'English',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profileImage'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
      address: json['address'],
      emergencyContacts: List<String>.from(json['emergencyContacts'] ?? []),
      medicalHistory: Map<String, dynamic>.from(json['medicalHistory'] ?? {}),
      allergies: List<String>.from(json['allergies'] ?? []),
      preferredLanguage: json['preferredLanguage'] ?? 'English',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'emergencyContacts': emergencyContacts,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'preferredLanguage': preferredLanguage,
    };
  }
}
