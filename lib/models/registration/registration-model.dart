import 'package:dio/dio.dart';

class UserRegistrationModel {
  final String username;
  final String email;
  final String password;

  UserRegistrationModel({
    required this.username,
    required this.email,
    required this.password
  });


  FormData toFormData() {
    return FormData.fromMap({
      "username": username,
      "email": email,
      "password": password,
    });
  }
}
