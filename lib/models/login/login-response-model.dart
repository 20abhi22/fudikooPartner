class LoginResponseModel {
  final bool status;
  final String message;
  final String? token;

  LoginResponseModel({required this.status, required this.message, this.token});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      status: json['status'] ?? false,
      message:
          json['message'] ??
          'Unknown error',
      token: json['token'],
    );
  }
}
