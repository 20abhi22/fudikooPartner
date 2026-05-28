import 'package:dio/dio.dart';

class UserLoginModel {
  final String username;
  final String password;

  UserLoginModel({required this.username, required this.password});

  FormData toFormData() {
    return FormData.fromMap({"username": username, "password": password});
  }
}
