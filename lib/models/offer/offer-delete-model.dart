import 'package:dio/dio.dart';

class OfferDeleteModel {
  final String offerId;
  OfferDeleteModel({required this.offerId});
  FormData toFormData() {
    return FormData.fromMap({"offer_id": offerId});
  }
}

class OfferDeleteResponseModel {
  final bool status;
  final String message;

  OfferDeleteResponseModel({required this.status, required this.message});

  factory OfferDeleteResponseModel.fromJson(Map<String, dynamic> json) {
    return OfferDeleteResponseModel(
      status: json['status'],
      message: json['message'],
    );
  }
}
