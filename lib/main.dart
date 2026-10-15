import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/screens/others/splashScreen.dart';
import 'package:fudiko/services/push-notification-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/http_overrides.dart';
import 'package:fudiko/utils/route_observer.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android reads its Firebase config from google-services.json via the
  // Google Services Gradle plugin, so no explicit FirebaseOptions are
  // needed here. iOS has no GoogleService-Info.plist configured yet.
  await Firebase.initializeApp();
  PushNotificationService.init();

  await TranslatorService.loadSavedLanguage();

  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // Without Hybrid Composition, GoogleMap always paints on top of the
  // native Android view hierarchy regardless of Flutter's Stack order,
  // so overlay widgets (e.g. the map picker's search dropdown) render
  // underneath the map and never appear on top of it.
  if (!kIsWeb && Platform.isAndroid) {
    final mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

  runApp(
    OrientationBuilder(
      builder: (context, orientation) {
        final designSize = orientation == Orientation.landscape
            ? const Size(874, 402)
            : const Size(402, 874);

        return ScreenUtilInit(
          designSize: designSize,
          minTextAdapt: true,
          builder: (context, child) => const MyApp(),
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fudiko Partner App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: appTextColor),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      scaffoldMessengerKey: messengerKey,
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
    );
  }
}
