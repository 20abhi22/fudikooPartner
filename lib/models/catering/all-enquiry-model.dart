class CateringEnquiryModel {
  final String uuid;
  final String enquiryId;
  final String userId;
  final String customerId;
  final String lat;
  final String lng;
  final String menuItems;
  final String otherServices;
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

  CateringEnquiryModel({
    required this.uuid,
    required this.enquiryId,
    required this.userId,
    required this.customerId,
    required this.lat,
    required this.lng,
    required this.menuItems,
    required this.otherServices,
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

  factory CateringEnquiryModel.fromJson(Map<String, dynamic> json) {
    // Completed enquiries return their accepted offer inside `selected_offer`.
    // Other enquiry endpoints can still provide these values at the top level.
    final selectedOffer = json['selected_offer'];
    final selectedOfferMap = selectedOffer is Map<String, dynamic>
        ? selectedOffer
        : const <String, dynamic>{};

    return CateringEnquiryModel(
      uuid: json['uuid'] ?? '',
      enquiryId: json['enquiry_id'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      lat: json['lat']?.toString() ?? '',
      lng: json['lng']?.toString() ?? '',
      menuItems: json['menu_items'] ?? '',
      otherServices: json['other_services'] ?? '',
      people: json['people'] ?? 0,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      estimatedAmount: json['estimated_amount']?.toString() ?? '',
      amount: (selectedOfferMap['amount'] ?? json['amount'])?.toString() ?? '',
      extraOffer:
          (selectedOfferMap['extra_offer'] ?? json['extra_offer'])
              ?.toString() ??
          '',
      comments:
          (selectedOfferMap['comments'] ?? json['comments'])?.toString() ?? '',
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
