class SentEnquiryModel {
  final String uuid;
  final String enquiryId;
  final String date;
  final String time;
  final String amount;
  final String extraOffer;
  final String comments;

  SentEnquiryModel({
    required this.uuid,
    required this.enquiryId,
    required this.date,
    required this.time,
    required this.amount,
    required this.extraOffer,
    required this.comments,
  });

  factory SentEnquiryModel.fromJson(Map<String, dynamic> json) {
    return SentEnquiryModel(
      uuid: json['uuid'] ?? '',
      enquiryId: json['enquiry_id'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      amount: json['amount'] ?? '',
      extraOffer: json['extra_offer'] ?? '',
      comments: json['comments'] ?? '',
    );
  }
}

class SentEnquiryListResponse {
  final bool status;
  final List<SentEnquiryModel> enquiries;

  SentEnquiryListResponse({required this.status, required this.enquiries});

  factory SentEnquiryListResponse.fromJson(Map<String, dynamic> json) {
    return SentEnquiryListResponse(
      status: json['status'] ?? false,
      enquiries: (json['enquiries'] as List)
          .map((e) => SentEnquiryModel.fromJson(e))
          .toList(),
    );
  }
}