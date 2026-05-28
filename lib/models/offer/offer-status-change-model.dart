import 'package:dio/dio.dart';

class OfferStatusChangeModel{
  final String offerId;

  OfferStatusChangeModel(this.offerId);

  FormData toFormData(){
    return FormData.fromMap({
      "offer_id" : offerId
    });
  }
}
class OfferStatusChangeReturnModel{
  final bool status;
  final String message;

  OfferStatusChangeReturnModel({required this.status, required this.message});

  factory OfferStatusChangeReturnModel.fromJson(Map<String, dynamic> json) {
    return OfferStatusChangeReturnModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}
