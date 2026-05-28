import 'dart:io';
import 'package:dio/dio.dart';

Future<void> main() async {
  final baseUrl = 'https://fudikko.bitwissenddev.in/api';
  final token = Platform.environment['API_TOKEN'];

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true, requestHeader: true));

  final headers = <String, String>{'Accept': 'application/json'};
  if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';

  try {
    print('Calling $baseUrl/partner/profile');
    if (token != null) print('Using token from API_TOKEN env var');

    final response = await dio.get('/partner/profile', options: Options(headers: headers));
    print('Status: ${response.statusCode}');
    print('Response data:\n${response.data}');
  } on DioError catch (e) {
    print('DioError: ${e.type}');
    if (e.response != null) {
      print('Status code: ${e.response?.statusCode}');
      print('Body: ${e.response?.data}');
    } else {
      print('Error message: ${e.message}');
    }
    exit(1);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
