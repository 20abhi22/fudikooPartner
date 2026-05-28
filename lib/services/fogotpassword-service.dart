import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/forgotpassword/changepassword-model.dart';
import 'package:fudiko/models/forgotpassword/finduser-model.dart';

class ForgotPasswordService{
  Map<String, dynamic>? _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return null;
  }

  Future<FindUserResponseModel> findUser(FindUserModel user) async{
    final formData = user.toFormData();
    try{
      final response = await DioClient.dio.post(
        '/find-user',
        data: formData
      );
      final responseData = _asJsonMap(response.data);
      if (responseData != null) {
        return FindUserResponseModel.fromJson(responseData);
      }

      return FindUserResponseModel(
        status: response.statusCode == 200 || response.statusCode == 201,
        message: "No user found",
        token: null,
      );
    } on DioException catch (e) {
      final responseData = _asJsonMap(e.response?.data);
      return FindUserResponseModel(
        status: false,
        message: responseData?['message']?.toString() ?? "Something went wrong : ${e.message}",
        token: responseData?['token']?.toString(),
      );
    }catch(e){
      return FindUserResponseModel(
        status: false,
        message: "Something went wrong : $e"
      );
    }
  }

  Future<NewPasswordResponseModel> changePassword(NewPasswordModel user,String? token) async{

    final formData = user.toFormData();
    try{
      final response = await DioClient.dio.post(
        '/change-password',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final responseData = _asJsonMap(response.data);
      if (responseData != null) {
        return NewPasswordResponseModel.fromJson(responseData);
      }

      return NewPasswordResponseModel(
        message: "Password change failed: ${response.statusCode}",
        status: false,
      );
    } on DioException catch (e) {
      final responseData = _asJsonMap(e.response?.data);
      return NewPasswordResponseModel(
        status: false,
        message: responseData?['message']?.toString() ?? "Something went wrong : ${e.message}",
      );
    }catch(e){
      return NewPasswordResponseModel(
          status: false,
          message: "Something went wrong : $e"
      );
    }
  }


}