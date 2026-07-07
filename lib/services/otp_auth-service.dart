import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/registration/otp-model.dart';
import 'package:fudiko/utils/tokens.dart';
class OtpAuthService {
Future<SendOtpResponseModel> sendOtp({String? tokenOverride}) async {
  try {
    final token = tokenOverride ?? await getToken();
    final response = await DioClient.dio.get(
      '/send-otp',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SendOtpResponseModel.fromJson(response.data);
    } else {
      return SendOtpResponseModel(status: false, message: 'Failed: ${response.statusCode}');
    }
  } catch (e) {
    return SendOtpResponseModel(status: false, message: 'Something went wrong: $e');
  }
}

Future<VerifyOtpResponseModel> verifyOtp(String otp, String otpId, {String? tokenOverride}) async {
  try {
    final token = tokenOverride ?? await getToken();
    final formData = FormData.fromMap({'otp': otp, 'otp_id': otpId});
    final response = await DioClient.dio.post(
      '/verify-otp',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return VerifyOtpResponseModel.fromJson(response.data);
    } else {
      return VerifyOtpResponseModel(status: false, message: 'Failed: ${response.statusCode}');
    }
  } catch (e) {
    return VerifyOtpResponseModel(status: false, message: 'Something went wrong: $e');
  }
}
}