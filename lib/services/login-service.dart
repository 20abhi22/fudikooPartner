import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/login/login-model.dart';
import 'package:fudiko/models/login/login-response-model.dart';
import 'package:fudiko/utils/error_messages.dart';

class LoginAuthService {
  Future<LoginResponseModel> loginUser(UserLoginModel user) async {
    try {
      final formData = user.toFormData();

      final response = await DioClient.dio.post(
        '/login',
        data: formData,
      );

      if (response.statusCode == 200) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        return LoginResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: 'We could not sign you in. Please try again.',
          ),
          token: null,
        );
      }
    } catch (e) {
      return LoginResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: 'We could not sign you in. Please try again.',
        ),
        token: null,
      );
    }
  }
}
