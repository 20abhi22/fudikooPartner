import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/utils/tokens.dart';

class DeviceTokenService {
  /// Requests notification permission, then fetches the FCM device token and
  /// registers it with the backend. Also registers it again on every token
  /// refresh, since the OS can rotate it at any time while the app is logged
  /// in. Called fire-and-forget after login and on auto-login from the
  /// splash screen, so a push-permission denial or network failure here must
  /// never block navigation.
  Future<void> registerDeviceToken() async {
    try {
      await FirebaseMessaging.instance.requestPermission();

      final deviceToken = await FirebaseMessaging.instance.getToken();
      if (deviceToken != null) {
        await sendDeviceToken(deviceToken);
      }

      // One listener for the whole process: registerDeviceToken runs on every
      // login, so without the cancel they would stack up.
      await _refreshSub?.cancel();
      _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        sendDeviceToken,
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  static StreamSubscription<String>? _refreshSub;

  /// Registers one FCM token with the backend. Never throws: it also runs
  /// from the token-refresh stream, where an error would go unhandled.
  /// Expected endpoint: POST /partner/device-token
  Future<void> sendDeviceToken(String deviceToken) async {
    try {
      final token = await getToken();
      await DioClient.dio.post(
        '/partner/device-token',
        data: FormData.fromMap({'device_token': deviceToken}),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  /// Stops pushes reaching this device once the user logs out. Must run
  /// before the auth token is removed, since the backend call needs it.
  /// Best-effort: deleting the FCM token locally invalidates it for FCM even
  /// if the backend call fails.
  /// Expected endpoint: DELETE /partner/device-token
  Future<void> unregisterDeviceToken() async {
    try {
      await _refreshSub?.cancel();
      _refreshSub = null;

      final deviceToken = await FirebaseMessaging.instance.getToken();
      final token = await getToken();
      if (deviceToken != null && token != null) {
        await DioClient.dio.delete(
          '/partner/device-token',
          data: FormData.fromMap({'device_token': deviceToken}),
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
