import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/utils/tokens.dart';
import 'package:dio/dio.dart';

class NotificationBadgesService {
  /// Fetches badge counts from the backend.
  /// Expected endpoint: GET /partner/notification/badges
  /// Returns a map with keys like 'reservation', 'enquiries', 'catering'.
  Future<Map<String, int>> getBadges() async {
    final token = await getToken();
    final response = await DioClient.dio.get(
      '/partner/notification/badges',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.data == null || response.data['status'] != true) {
      return {};
    }

    final main = response.data['main'] as Map<String, dynamic>?;
    if (main == null) return {};

    return main.map((k, v) => MapEntry(k, (v is int) ? v : int.tryParse('$v') ?? 0));
  }
}
