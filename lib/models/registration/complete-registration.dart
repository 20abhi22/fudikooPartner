import 'dart:io';
import 'package:dio/dio.dart';

class CompleteRegistrationModel {
  final String name;
  final String type;
  final String address;
  final String phone;
  final String lat;
  final String lng;
  final String description;
  final String availableDishes;
  final String banquetService;
  final String takeawayService;
  final String deliveryService;
  final String deliveryServiceArea;
  final String restaurantTypw;
  final File? image;


  CompleteRegistrationModel({
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.description,
    required this.availableDishes,
    required this.banquetService,
    required this.takeawayService,
    required this.deliveryService,
    required this.deliveryServiceArea,
    required this.restaurantTypw,
    this.image,
  });

  FormData toFormData() {
final Map<String, dynamic> map  = {
      "name" : name,
      "type" : type,
      "address" : address,
      "phone" : phone,
      "lat" : lat,
      "lng" : lng,
      "description" : description,
      "available_dishes" : availableDishes,
      "banquet_service" : banquetService,
      "takeaway_service" : takeawayService,
      "delivery_service" : deliveryService,
      "delivery_service_area" : deliveryServiceArea,
      "restaurant_type" : restaurantTypw,
    };

    if (image != null) {
      map["image"] = MultipartFile.fromFileSync(
        image!.path,
        filename: image!.path.split('/').last,
      );
    }

    return FormData.fromMap(map);
  }
}

class CompleteRegistrationModelResponse {
  final String message;
  final bool status;
  CompleteRegistrationModelResponse({required this.message, required this.status});

  factory CompleteRegistrationModelResponse.fromJson(Map<String, dynamic> json) {
    return CompleteRegistrationModelResponse(message: json['message'], status: json['status']);
  }

}
