class OtpVerifiedResponseModel {
  final bool status;
  final String message;

  OtpVerifiedResponseModel({required this.status, required this.message});

  factory OtpVerifiedResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpVerifiedResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}
