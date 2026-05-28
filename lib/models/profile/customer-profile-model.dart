class CustomerProfileModel {
  final String badge;
  final int rating;
  final String name;
  final String email;
  final String place;
  final String contactInfo;
  final String profilePicture;

  CustomerProfileModel({
    required this.badge,
    required this.rating,
    required this.name,
    required this.email,
    required this.place,
    required this.contactInfo,
    required this.profilePicture,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      badge: json['badge'] ?? '-',
      rating: json['rating'] ?? 0,
      name: json['name'] ?? '-',
      email: json['email'] ?? '-',
      place: json['place'] ?? '-',
      contactInfo: json['contact_info'] ?? '-',
      profilePicture: json['profile_picture'] ?? '-',
    );
  }
}