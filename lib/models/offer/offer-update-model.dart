import 'package:dio/dio.dart';

class EditOfferModel {
  final String? discountPercentage;
  final String? applicableFor;
  final String? dineType;
  final String? startTime;
  final String? endTime;
  final String? activeDays;
  final String? uuid;

  EditOfferModel({
    this.discountPercentage,
    this.applicableFor,
    this.dineType,
    this.startTime,
    this.endTime,
    this.activeDays,
    this.uuid,
  });

  FormData toFormData() {
    return FormData.fromMap({
      "discount_percentage": discountPercentage,
      "applicable_for": applicableFor,
      "dine_type": dineType,
      "start_time": startTime,
      "end_time": endTime,
      "active_days": activeDays,
      "offer_id": uuid,
    });
  }
}

class OfferEditReturnModel {
  final bool status;
  final String message;

  OfferEditReturnModel({required this.status, required this.message});

  factory OfferEditReturnModel.fromJson(Map<String, dynamic> json) {
    return OfferEditReturnModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}
