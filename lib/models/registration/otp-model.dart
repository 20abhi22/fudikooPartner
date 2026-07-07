class SendOtpResponseModel {
  final bool status;
  final String message;
  final String? otpId;

  SendOtpResponseModel({required this.status, required this.message, this.otpId});

  factory SendOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return SendOtpResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      otpId: json['otp']?.toString(),
    );
  }
}

class VerifyOtpResponseModel {
  final bool status;
  final String message;

  VerifyOtpResponseModel({required this.status, required this.message});

  factory VerifyOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
    );
  }
}