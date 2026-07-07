import 'package:fudiko/models/badge/badge_model.dart';

class CustomerProfileModel {
  final String badge;
  final int rating;
  final String name;
  final String email;
  final String place;
  final String contactInfo;
  final String profilePicture;
  final String lat;
  final String lng;
  final BadgeItemModel? currentBadge;

  CustomerProfileModel({
    required this.badge,
    required this.rating,
    required this.name,
    required this.email,
    required this.place,
    required this.contactInfo,
    required this.profilePicture,
    required this.lat,
    required this.lng,
    this.currentBadge,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : json;
    final lat = customer['lat']?.toString() ?? '';
    final lng = customer['lng']?.toString() ?? '';
    final currentBadgeJson = json['current_badge'] is Map<String, dynamic>
        ? json['current_badge'] as Map<String, dynamic>
        : customer['current_badge'] is Map<String, dynamic>
        ? customer['current_badge'] as Map<String, dynamic>
        : null;
    final currentBadge = currentBadgeJson == null
        ? null
        : BadgeItemModel.fromJson(currentBadgeJson);

    return CustomerProfileModel(
      badge: currentBadge?.name ?? customer['badge']?.toString() ?? '-',
      rating: _parseRating(
        customer['reliability_rating'] ??
            json['reliability_rating'] ??
            customer['rating'],
      ),
      name: customer['name']?.toString() ?? '-',
      email: customer['email']?.toString() ?? '-',
      place:
          customer['place']?.toString() ??
          (lat.isNotEmpty && lng.isNotEmpty ? '$lat, $lng' : '-'),
      contactInfo:
          customer['contact_info']?.toString() ??
          customer['phone']?.toString() ??
          '-',
      profilePicture: customer['profile_picture']?.toString() ?? '',
      lat: lat,
      lng: lng,
      currentBadge: currentBadge,
    );
  }

  static int _parseRating(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
