import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/registration/complete-registration.dart';
import 'package:fudiko/models/registration/registration-model.dart';
import 'package:fudiko/models/registration/registration-response-model.dart';
import 'package:fudiko/utils/tokens.dart';

class RegistrationAuthService {
  Future<RegResponseModel> registerUser(UserRegistrationModel user) async {
    try {
        final formData = user.toFormData();

        final response = await DioClient.dio.post(
          '/register/',
          data: formData,
        );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.data);
        return RegResponseModel.fromJson(response.data);
      } else {
        return RegResponseModel(
          status: false,
          message: 'Registration failed: ${response.statusCode}',
          token: null,
        );
      }
    } catch (e) {
      return RegResponseModel(
        status: false,
        message: 'Something went wrong: $e',
        token: null,
      );
    }
  }
  Future<CompleteRegistrationModelResponse> completeRegistration(CompleteRegistrationModel details) async {
    try{
        final formData = details.toFormData();
        final token = await getToken();
      final response = await DioClient.dio.post('/partner/complete-registration', data: formData,options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = {
          "status": response.data['status'],
          "message": response.data['message']
        };
        print('=========================================');
        print(response.data);
        print('=========================================');
        return CompleteRegistrationModelResponse.fromJson(data);
      }else{
        return CompleteRegistrationModelResponse(status: false, message: "Registration failed!");
      }
    }catch(e){
      print(e);
      return CompleteRegistrationModelResponse(status: false, message: "Something went wrong : $e");
    }
  }

}
