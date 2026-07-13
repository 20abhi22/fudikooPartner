class LoginResponseModel {
  final bool status;
  final String message;
  final String? token;
  final bool isRegistered;
  final bool otpVerified;

  LoginResponseModel({
    required this.status,
    required this.message,
    this.token,
    this.isRegistered = true,
    this.otpVerified = true,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
      token: json['token'],
      isRegistered: json['is_registered'] ?? true,
      otpVerified: json['otp_verified'] ?? true,
    );
  }
}