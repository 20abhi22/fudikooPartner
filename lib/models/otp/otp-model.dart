import 'package:dio/dio.dart';

class OtpVerifyModel {
  final String otp;
  final String otpId;

  OtpVerifyModel({required this.otp, required this.otpId});

  FormData toFormData() {
    return FormData.fromMap({"otp": otp, "otp_id": otpId});
  }
}
