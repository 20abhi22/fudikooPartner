import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/profile/customer-profile-model.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/utils/tokens.dart';

class PartnerService {
  String _imageSubtype(File imageFile) {
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (extension == 'jpg' || extension == 'jpeg') return 'jpeg';
    if (extension == 'png') return 'png';
    if (extension == 'webp') return 'webp';
    return 'jpeg';
  }

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
      'image': await MultipartFile.fromFile(
        imageFile.path,
        contentType: MediaType('image', _imageSubtype(imageFile)),
      ),
    });
    final response = await DioClient.dio.post(
      '/partner/restaurant-images/create',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteRestaurantImage(String uuid) async {
    final token = await getToken();
    final response = await DioClient.dio.post(
      '/partner/restaurant-images/delete',
      data: FormData.fromMap({'uuid': uuid}),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfilePhoto(File imageFile) async {
    final token = await getToken();
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        contentType: MediaType('image', _imageSubtype(imageFile)),
      ),
    });
    final response = await DioClient.dio.post(
      '/partner/update-image',
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
  Future<CustomerProfileModel> getProfile(String customerId) async {
    final token = await getToken();
    final response = await DioClient.dio.post(
      '/partner/customer',
      data: FormData.fromMap({'customer_id': customerId}),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return CustomerProfileModel.fromJson(response.data);
  }
}
