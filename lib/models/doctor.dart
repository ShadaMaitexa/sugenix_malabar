class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String? profileImage;
  final double rating;
  final int totalBookings;
  final int totalPatients;
  final int likes;
  final String? experience;
  final String? education;
  final String? hospital;
  final List<String> languages;
  final Map<String, List<String>> availability;
  final double consultationFee;
  final String? bio;
  final bool isOnline;
  final bool isFavorite;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    this.profileImage,
    this.rating = 0.0,
    this.totalBookings = 0,
    this.totalPatients = 0,
    this.likes = 0,
    this.experience,
    this.education,
    this.hospital,
    this.languages = const [],
    this.availability = const {},
    this.consultationFee = 0.0,
    this.bio,
    this.isOnline = false,
    this.isFavorite = false,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      profileImage: json['profileImage'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalBookings: json['totalBookings'] ?? 0,
      totalPatients: json['totalPatients'] ?? 0,
      likes: json['likes'] ?? 0,
      experience: json['experience'],
      education: json['education'],
      hospital: json['hospital'],
      languages: List<String>.from(json['languages'] ?? []),
      availability: Map<String, List<String>>.from(json['availability'] ?? {}),
      consultationFee: (json['consultationFee'] ?? 0.0).toDouble(),
      bio: json['bio'],
      isOnline: json['isOnline'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'profileImage': profileImage,
      'rating': rating,
      'totalBookings': totalBookings,
      'totalPatients': totalPatients,
      'likes': likes,
      'experience': experience,
      'education': education,
      'hospital': hospital,
      'languages': languages,
      'availability': availability,
      'consultationFee': consultationFee,
      'bio': bio,
      'isOnline': isOnline,
      'isFavorite': isFavorite,
    };
  }
}
