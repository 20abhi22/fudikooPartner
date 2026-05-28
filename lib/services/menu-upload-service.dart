import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/menuupload/menu-delete-model.dart';
import 'package:fudiko/models/menuupload/menu-list-model.dart';
import 'package:fudiko/models/menuupload/menu-update-model.dart';
import 'package:fudiko/models/menuupload/menu-upload-model.dart';
import 'package:fudiko/utils/tokens.dart';

class MenuUploadService {
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
