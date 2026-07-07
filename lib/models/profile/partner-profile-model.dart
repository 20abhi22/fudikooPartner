import 'package:fudiko/models/badge/badge_model.dart';

class RestaurantImageModel {
  final String uuid;
  final String image;

  const RestaurantImageModel({required this.uuid, required this.image});

  factory RestaurantImageModel.fromJson(Map<String, dynamic> json) {
    return RestaurantImageModel(
      uuid: json['uuid']?.toString() ?? '',
      image: json['image'] != null
          ? (json['image'] as String).replaceAll(r'\/', '/')
          : '',
    );
  }
}

class PartnerProfileModel {
  final String uuid;
  final String name;
  final String type;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final String description;
  final String availableDishes;
  final int banquetService;
  final int cateringService; // ← added
  final int takeawayService;
  final int deliveryService;
  final String? deliveryServiceArea; // ← added (comma-separated)
  final String reviewStar;
  final String restaurantType;
  final String? image;
  final List<String>? images;
  final List<RestaurantImageModel>? restaurantImages;
  final BadgeItemModel? currentBadge;

  PartnerProfileModel({
    required this.uuid,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.description,
    required this.availableDishes,
    required this.banquetService,
    required this.cateringService,
    required this.takeawayService,
    required this.deliveryService,
    this.deliveryServiceArea,
    required this.restaurantType,
    this.image,
    this.images,
    this.restaurantImages,
    required this.reviewStar,
    this.currentBadge,
  });

  factory PartnerProfileModel.fromJson(Map<String, dynamic> json) {
    final restaurantImages = json['images'] != null
        ? (json['images'] as List)
              .whereType<Map<String, dynamic>>()
              .map(RestaurantImageModel.fromJson)
              .where((image) => image.image.isNotEmpty)
              .toList()
        : null;

    return PartnerProfileModel(
      uuid: json['uuid'] ?? '',
      reviewStar: (json['average_review'] ?? 0).toString(),
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone']?.toString() ?? '',
      lat:
          double.tryParse((json['lat'] ?? json['latitude'] ?? 0).toString()) ??
          0,
      lng:
          double.tryParse((json['lng'] ?? json['longitude'] ?? 0).toString()) ??
          0,
      description: json['description'] ?? '',
      availableDishes: json['available_dishes'] ?? '',
      banquetService: json['banquet_service'] ?? 0,
      cateringService: json['catering_service'] ?? 0,
      takeawayService: json['takeaway_service'] ?? 0,
      deliveryService: json['delivery_service'] ?? 0,
      deliveryServiceArea: json['delivery_service_area'] as String?,
      restaurantType: json['restaurant_type'] ?? '',
      currentBadge:
          json['current_badge'] != null &&
              json['current_badge'] is Map<String, dynamic>
          ? BadgeItemModel.fromJson(
              json['current_badge'] as Map<String, dynamic>,
            )
          : null,
      image: json['image'] != null
          ? (json['image'] as String).replaceAll(r'\/', '/')
          : null,
      images: restaurantImages?.map((image) => image.image).toList(),
      restaurantImages: restaurantImages,
    );
  }
}
