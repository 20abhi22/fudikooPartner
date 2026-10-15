
import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-delete-model.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-edit-model.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-list-model.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-upload-model.dart';
import 'package:fudiko/utils/error_messages.dart';
import 'package:fudiko/utils/tokens.dart';

class IndividualMenuUploadService{
  String _uploadErrorMessage(DioException error) {
    if (error.response?.statusCode == 413) {
      return 'Image is too large. The maximum size is 10 MB.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Upload timed out. Check your connection and try again.';
    }
    final data = error.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
        }
      }
      return data['message']?.toString() ?? 'Menu item upload failed.';
    }
    return 'Menu item upload failed.';
  }

  Future<IndividualMenuUploadResponseModel> createMenu(IndividualMenuUploadModel menu) async{
    final token = await getToken();
    final formData = await menu.toFormData();
    try{
      final response = await DioClient.dio.post(
        '/partner/individual-menus/create',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        return IndividualMenuUploadResponseModel.fromJson(response.data);
      }else{
        return IndividualMenuUploadResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: "We could not add the menu item. Please try again.",
          ),
        );
      }
    } on DioException catch (e) {
      return IndividualMenuUploadResponseModel(
        status: false,
        message: _uploadErrorMessage(e),
      );
    } catch(e){
      return IndividualMenuUploadResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: "Menu item upload failed. Please try again.",
        ),
      );
    }
  }

  Future<IndividualMenuListModel> getAllMenus() async{
    final token = await getToken();
    try{
      final response = await DioClient.dio.get(
        '/partner/individual-menus/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        print(response.data);
        return IndividualMenuListModel.fromJson(response.data);
      }else{

        return IndividualMenuListModel(status: false, menus: []);
      }
    }catch(e){
      print("Error occurs");
      return IndividualMenuListModel(status: false, menus: []);
    }
  }

  Future<IndividualMenuEditResponseModel> updateMenu(IndividualMenuEditModel menu) async{
    final token = await getToken();
    try{
      final response = await DioClient.dio.post(
        '/partner/individual-menus/update',
        data: await menu.toFormData(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        print(response.data);
        return IndividualMenuEditResponseModel.fromJson(response.data);
      }else{
        print(response.data);
        return IndividualMenuEditResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: "We could not update the menu item. Please try again.",
          ),
        );
      }
    } on DioException catch (e) {
      return IndividualMenuEditResponseModel(
        status: false,
        message: _uploadErrorMessage(e),
      );
    } catch(e){
      print(e);
      return IndividualMenuEditResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: "We could not update the menu item. Please try again.",
        ),
      );
    }
  }

  Future<IndividualMenuDeleteResponseModel> deleteMenu(IndividualMenuDeleteModel menu) async{
    final token = await getToken();
    try{
      final response = await DioClient.dio.post(
        '/partner/individual-menus/delete',
        data: await menu.toFormData(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        return IndividualMenuDeleteResponseModel.fromJson(response.data);
      }else{
        return IndividualMenuDeleteResponseModel(
          status: false,
          message: statusCodeMessage(
            response.statusCode,
            fallback: "We could not delete the menu item. Please try again.",
          ),
        );
      }
    }catch(e){
      return IndividualMenuDeleteResponseModel(
        status: false,
        message: friendlyErrorMessage(
          e,
          fallback: "We could not delete the menu item. Please try again.",
        ),
      );
    }
  }


}
