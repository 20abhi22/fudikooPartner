class OfferReturnModel{
  final bool status;
  final String message;

  OfferReturnModel({required this.status, required this.message});

  factory OfferReturnModel.fromJson(Map<String, dynamic> json) {
    return OfferReturnModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }


}