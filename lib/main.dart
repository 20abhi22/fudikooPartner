import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/screens/others/splashScreen.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/http_overrides.dart';
import 'package:fudiko/utils/translator_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslatorService.loadSavedLanguage();

  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
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
      home: const SplashScreen(),
    );
  }
}
