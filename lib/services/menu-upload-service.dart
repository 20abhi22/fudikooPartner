import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/menuupload/menu-delete-model.dart';
import 'package:fudiko/models/menuupload/menu-list-model.dart';
import 'package:fudiko/models/menuupload/menu-update-model.dart';
import 'package:fudiko/models/menuupload/menu-upload-model.dart';
import 'package:fudiko/utils/tokens.dart';

class MenuUploadService {
  String _uploadErrorMessage(DioException error) {
    if (error.response?.statusCode == 413) {
      return 'PDF is too large. The maximum size is 10 MB.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Upload timed out. Check your connection and try again.';
    }
    final data = error.response?.data;
    if (data is Map) return data['message']?.toString() ?? 'PDF upload failed.';
    return 'PDF upload failed.';
  }

  Future<MenuUploadResponseModel> addMenu(MenuUploadModel menu) async {
    final token = await getToken();
    try {
      final formData = await menu.toFormData();
      final response = await DioClient.dio.post(
        '/partner/pdf-menus/upload',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MenuUploadResponseModel.fromJson(response.data);
      } else {
        return MenuUploadResponseModel(
          status: false,
          message: 'Error uploading MENU',
        );
      }
    } on DioException catch (e) {
      return MenuUploadResponseModel(status: false, message: _uploadErrorMessage(e));
    } catch (e) {
      return MenuUploadResponseModel(
        status: false,
        message: 'Something went wrong : $e',
      );
    }
  }

  Future<MenuListModel> getAllPdfMenus() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/partner/pdf-menus/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MenuListModel.fromJson(response.data);
      } else {
        return MenuListModel(status: false, menus: []);
      }
    } on DioException catch (e) {
      print('Error fetching menus: ${_uploadErrorMessage(e)}');
      return MenuListModel(status: false, menus: []);
    } catch (e) {
      print('Error fetching menus: $e');
      return MenuListModel(status: false, menus: []);
    }
  }

  Future<MenuUpdateResponseModel> updateMenu(MenuUpdateModel menu) async {
    final formData = await menu.toFormData();
    final token = await getToken();
    try {
      final response = await DioClient.dio.post(
        '/partner/pdf-menus/update',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MenuUpdateResponseModel.fromJson(response.data);
      } else {
        return MenuUpdateResponseModel(
          status: false,
          message: "Update failed! : ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      return MenuUpdateResponseModel(
        status: false,
        message: _uploadErrorMessage(e),
      );
    } catch (e) {
      return MenuUpdateResponseModel(
        status: false,
        message: "Something went wrong : $e",
      );
    }
  }

  Future<MenuDeleteResponseModel> deletePdf(MenuDeleteModel menu) async{
    final formData = menu.toFormData();
    final token = await getToken();
    try{
      final response = await DioClient.dio.post(
        '/partner/pdf-menus/delete',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if(response.statusCode == 200 || response.statusCode == 201){
        return MenuDeleteResponseModel.fromJson(response.data);
      }else{
        return MenuDeleteResponseModel(status: false, message: "Pdf deletion failed!");
      }
    }catch(e){
      return MenuDeleteResponseModel(status: false, message: "Something went wrong : $e");
    }
  }
}
