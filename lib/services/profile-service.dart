
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/profile/customer-profile-model.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/utils/tokens.dart';

class PartnerService {
  Future<PartnerProfileModel> getProfile() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return PartnerProfileModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> uploadRestaurantImage(File imageFile) async {
    final token = await getToken();
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await DioClient.dio.post(
      '/partner/restaurant-images/create',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String type,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    required String description,
    required String availableDishes,
    required String restaurantType,
  }) async {
    final token = await getToken();
    final response = await DioClient.dio.post(
      '/partner/update',
      data: {
        'name': name,
        'type': type,
        'address': address,
        'phone': phone,
        'lat': lat,
        'lng': lng,
        'description': description,
        'available_dishes': availableDishes,
        'restaurant_type': restaurantType,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

}
class CustomerProfileService {
  Future<CustomerProfileModel> getProfile() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/customer/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CustomerProfileModel.fromJson(response.data);
  }
}