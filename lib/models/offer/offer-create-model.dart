  import 'package:dio/dio.dart';

class CreateOfferModel {
  final String? discountPercentage;
  final String? applicableFor;
  final String? dineType;
  final String? startTime;
  final String? endTime;
  final String? activeDays;

  CreateOfferModel({
    this.discountPercentage,
    this.applicableFor,
    this.dineType,
    this.startTime,
    this.endTime,
    this.activeDays
  });

  FormData toFormData(){
    return FormData.fromMap(
      {
        "discount_percentage": discountPercentage,
        "applicable_for": applicableFor,
        "dine_type": dineType,
        "start_time": startTime,
        "end_time": endTime,
        "active_days" : activeDays
      }
    );
  }

}
