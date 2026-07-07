class BanquetEnquiryModel {
  final String uuid;
  final String enquiryId;
  final String userId;
  final String customerId;
  final String lat;
  final String lng;
  final String menuItems;
  final int people;
  final String date;
  final String time;
  final String estimatedAmount;
  final String? amount;
  final String? extraOffer;
  final String? comments;
  final String searchRadius;
  final String expirationDate;
  final String expirationTime;
  final String status;

  BanquetEnquiryModel({
    required this.uuid,
    required this.enquiryId,
    required this.userId,
    required this.customerId,
    required this.lat,
    required this.lng,
    required this.menuItems,
    required this.people,
    required this.date,
    required this.time,
    required this.estimatedAmount,
    required this.amount,
    required this.extraOffer,
    required this.comments,
    required this.searchRadius,
    required this.expirationDate,
    required this.expirationTime,
    required this.status,
  });

  factory BanquetEnquiryModel.fromJson(Map<String, dynamic> json) {
    return BanquetEnquiryModel(
      uuid: json['uuid'] ?? '',
      enquiryId: json['enquiry_id'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      lat: json['lat']?.toString() ?? '',
      lng: json['lng']?.toString() ?? '',
      menuItems: json['menu_items'] ?? '',
      people: json['people'] ?? 0,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      estimatedAmount: json['estimated_amount']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      extraOffer: json['extra_offer']?.toString() ?? '',
      comments: json['comments']?.toString() ?? '',
      searchRadius: json['search_radius']?.toString() ?? '',
      expirationDate: json['expiration_date'] ?? '',
      expirationTime: json['expiration_time'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class BanquetEnquiryListResponse {
  final bool status;
  final List<BanquetEnquiryModel> enquiries;

  BanquetEnquiryListResponse({required this.status, required this.enquiries});

  factory BanquetEnquiryListResponse.fromJson(Map<String, dynamic> json) {
    return BanquetEnquiryListResponse(
      status: json['status'] ?? false,
      enquiries: (json['enquiries'] as List)
          .map((e) => BanquetEnquiryModel.fromJson(e))
          .toList(),
    );
  }
}
