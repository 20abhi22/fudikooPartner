class OfferModel {
    final String uuid;
    final String partnerUid;
    final String discountPercentage;
    final String applicableFor;
    final String dineType;
    final String startTime;
    final String endTime;
    final String activeDays;
    final String status;

  OfferModel({
    required this.uuid,
    required this.partnerUid,
    required this.discountPercentage,
    required this.applicableFor,
    required this.dineType,
    required this.startTime,
    required this.endTime,
    required this.activeDays,
    required this.status,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      uuid: json['uuid'],
      partnerUid: json['partner_uid'],
      discountPercentage: json['discount_percentage'],
      applicableFor: json['applicable_for'],
      dineType: json['dine_type'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      activeDays: json['active_days'],
      status: json['status'],
    );
  }
}

class OfferListResponse {
  final bool status;
  final List<OfferModel> offers;

  OfferListResponse({required this.status, required this.offers});

  factory OfferListResponse.fromJson(Map<String, dynamic> json) {
    return OfferListResponse(
      status: json['status'],
      offers: (json['offers'] as List)
          .map((item) => OfferModel.fromJson(item))
          .toList(),
    );
  }
}
