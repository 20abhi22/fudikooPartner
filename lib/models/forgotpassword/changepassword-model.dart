import 'package:dio/dio.dart';

class NewPasswordModel {
  final String newPassword;
  NewPasswordModel({required this.newPassword});
  FormData toFormData() {
    return FormData.fromMap({"password": newPassword});
  }
}

class NewPasswordResponseModel {
  final bool status;
  final String message;
  NewPasswordResponseModel({required this.message, required this.status});

  factory NewPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return NewPasswordResponseModel(
      message: json['message'],
      status: json['status'],
    );
  }
}
