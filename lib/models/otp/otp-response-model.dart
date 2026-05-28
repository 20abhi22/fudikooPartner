class OtpResponseModel {
  final bool status;
  final String message;
  final String? otp;

  OtpResponseModel({required this.status, required this.message, this.otp});

  factory OtpResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
      otp: json['otp'],
    );
  }
}
