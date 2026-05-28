import 'package:dio/dio.dart';

class FindUserModel {
  final String username;
  final String email;

  FindUserModel(this.username, this.email);

  FormData toFormData() {
    return FormData.fromMap({"username": username, "email": email});
  }
}



class FindUserResponseModel {
  final bool status;
  final String? message;
  final String? token;

  FindUserResponseModel({required this.status, this.message, this.token});

  factory FindUserResponseModel.fromJson(Map<String, dynamic> json) {
    return FindUserResponseModel(
      status: json['status'] ?? false,
      message: json['message'],
      token: json['token'],
    );
  }
}
