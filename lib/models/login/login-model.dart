import 'package:dio/dio.dart';

class UserLoginModel {
  final String username;
  final String password;
  final String type;

  UserLoginModel({
    required this.username,
    required this.password,
    this.type = 'partner',
  });

  FormData toFormData() {
    return FormData.fromMap({
      "username": username,
      "password": password,
      "type": type,
    });
  }
}
