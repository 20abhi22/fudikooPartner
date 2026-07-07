import 'package:fudiko/api/dio_client.dart';
// import 'package:fudiko/model/badge/badge_model.dart';
import 'package:fudiko/models/badge/badge_model.dart';

class BadgesService {
  BadgesService._internal();
  static final BadgesService _instance = BadgesService._internal();
  factory BadgesService() => _instance;

  Future<BadgesResponseModel?> getBadges() async {
    try {
      final response = await DioClient.dio.get('/partner/badges');
      if (response.statusCode == 200 && response.data != null) {
        return BadgesResponseModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('BadgesService.getBadges error: $e');
      return null;
    }
  }
}