import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Attached to the MaterialApp so a push that arrives while the app is open
/// can be shown from anywhere, without a BuildContext.
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Runs in its own isolate when a push arrives with the app in the
/// background or terminated, so it must be top-level and bring up Firebase
/// itself. Messages that carry a `notification` payload are already drawn by
/// the OS; this exists so data-only messages don't throw.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  static StreamSubscription<RemoteMessage>? _foregroundSub;

  /// Call once from main() after Firebase.initializeApp(). The OS does not
  /// draw a notification while the app is in the foreground, so those are
  /// shown as a snackbar instead.
  static void init() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final title = notification?.title;
      final body = notification?.body;
      if (title == null && body == null) return;

      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                if (body != null) Text(body),
              ],
            ),
          ),
        );
    });
  }
}
