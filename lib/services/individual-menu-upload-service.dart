
import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-delete-model.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-edit-model.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-list-model.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-upload-model.dart';
import 'package:fudiko/utils/tokens.dart';

class IndividualMenuUploadService{
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
        return IndividualMenuUploadResponseModel(status: false, message: "Error adding menu : ${response.statusCode}");
      }
    }catch(e){
      return IndividualMenuUploadResponseModel(status: false, message: "Something went wrong : $e");
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
        return IndividualMenuEditResponseModel(status: false, message: "Menu update failed : ${response.statusCode}");
      }
    }catch(e){
      print(e);
      return IndividualMenuEditResponseModel(status: false, message: "Something went wrong : $e");
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
        return IndividualMenuDeleteResponseModel(status: false, message: "Menu delete failed! : ${response.statusCode}");
      }
    }catch(e){
      return IndividualMenuDeleteResponseModel(status: false, message: "Something went wrong : $e");
    }
  }


}