import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudiko/api/api_config.dart';
import 'package:fudiko/utils/tokens.dart';

class DioClient {
  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          handler.next(options);
        },
        onError: (DioException err, handler) async {
          if (err.response?.statusCode == 401) {
            try {
              await removeToken();
            } catch (_) {}
          }
          handler.next(err);
        },
      ),
    ]);

    // Request logging includes the bearer token and response bodies, so it is
    // limited to debug builds.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, requestHeader: true),
      );
    }


    return dio;
  }
}
