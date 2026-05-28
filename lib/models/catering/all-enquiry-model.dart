class CateringEnquiryModel {
  final String uuid;
  final String enquiryId;
  final String userId;
  final String lat;
  final String lng;
  final String menuItems;
  final int people;
  final String date;
  final String time;
  final String estimatedAmount;
  final String searchRadius;
  final String expirationDate;
  final String expirationTime;
  final String status;

  CateringEnquiryModel({
    required this.uuid,
    required this.enquiryId,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.menuItems,
    required this.people,
    required this.date,
    required this.time,
    required this.estimatedAmount,
    required this.searchRadius,
    required this.expirationDate,
    required this.expirationTime,
    required this.status,
  });

  factory CateringEnquiryModel.fromJson(Map<String, dynamic> json) {
    return CateringEnquiryModel(
      uuid: json['uuid'] ?? '',
      enquiryId: json['enquiry_id'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      lat: json['lat']?.toString() ?? '',
      lng: json['lng']?.toString() ?? '',
      menuItems: json['menu_items'] ?? '',
      people: json['people'] ?? 0,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      estimatedAmount: json['estimated_amount']?.toString() ?? '',
      searchRadius: json['search_radius']?.toString() ?? '',
      expirationDate: json['expiration_date'] ?? '',
      expirationTime: json['expiration_time'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class CateringEnquiryListResponse {
  final bool status;
  final List<CateringEnquiryModel> enquiries;

  CateringEnquiryListResponse({required this.status, required this.enquiries});

  factory CateringEnquiryListResponse.fromJson(Map<String, dynamic> json) {
    return CateringEnquiryListResponse(
      status: json['status'] ?? false,
      enquiries: (json['enquiries'] as List)
          .map((e) => CateringEnquiryModel.fromJson(e))
          .toList(),
    );
  }
}