import 'package:dio/dio.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/models/notification/notification-settings-model.dart';
import 'package:fudiko/utils/tokens.dart';

class NotificationSettingsService {
  Future<NotificationSettingsModel> getSettings() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/notification-settings',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return NotificationSettingsModel.fromJson(response.data);
  }

  Future<bool> saveSettings(NotificationSettingsModel settings) async {
    final token = await getToken();
    final response = await DioClient.dio.post(
      '/partner/notification-settings/store',
      data: settings.toJson(),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['status'] == true;
  }
}