import 'package:dio/dio.dart';

class MenuDeleteModel {
  final String id;

  MenuDeleteModel({required this.id});

  FormData toFormData() {
    return FormData.fromMap({"menu_id": id});
  }
}

class MenuDeleteResponseModel {
  final bool status;
  final String message;

  MenuDeleteResponseModel({required this.status, required this.message});

  factory MenuDeleteResponseModel.fromJson(Map<String, dynamic> json) {
    return MenuDeleteResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}