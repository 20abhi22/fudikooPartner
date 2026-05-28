import 'package:dio/dio.dart';

class IndividualMenuDeleteModel{
  final String menuId;

  IndividualMenuDeleteModel({required this.menuId});

  FormData toFormData(){
    return FormData.fromMap({
      "menu_id" : menuId
    });
  }
}

class IndividualMenuDeleteResponseModel{
  final bool status;
  final String message;

  IndividualMenuDeleteResponseModel({required this.status, required this.message});

  factory IndividualMenuDeleteResponseModel.fromJson(Map<String, dynamic> json) {
    return IndividualMenuDeleteResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}