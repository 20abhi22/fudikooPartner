
import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/otp/otp-model.dart';
import 'package:fudiko/models/otp/otp-response-model.dart';
import 'package:fudiko/models/otp/otp-verified-response-model.dart';
import 'package:fudiko/utils/tokens.dart';

class OtpService{
  Future<dynamic> sendOtp() async{
    final token = await getToken();
    print("Token : $token");
    try{
      final response = await DioClient.dio.get(
        '/send-otp',
        options: Options(
          headers: {
            'Authorization' : 'Bearer $token'
          }
        )
      );
      if(response.statusCode == 200){
        return OtpResponseModel.fromJson(response.data);
      }else{
        return OtpResponseModel(
          status: false,
          message: 'Otp send failed: ${response.statusCode}',
          otp: null,
        );
      }
    }catch(e){
      return OtpResponseModel(
        status: false,
        message: 'Something went wrong: $e',
        otp: null
      );
    }
  }

  Future<OtpVerifiedResponseModel> verifyOtp(OtpVerifyModel otp) async{
    final token = await getToken();
    final data = otp.toFormData();
    try{
      final response = await DioClient.dio.post(
        '/verify-otp',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'})
      );
      if(response.statusCode == 200){
        return OtpVerifiedResponseModel.fromJson(response.data);
      }else{
        return OtpVerifiedResponseModel(
          message: 'Otp verification failed: ${response.statusCode}',
          status: false
        );
      }
    }catch(e){
      return OtpVerifiedResponseModel(
        message: 'Something went wrong: $e',
        status: false
      );
    }
  }

}