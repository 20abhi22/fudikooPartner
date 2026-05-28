import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/screens/auth/otp.dart';
import 'package:fudiko/screens/auth/registration.dart';
import 'package:fudiko/screens/others/individualMenuUpload.dart';
import 'package:fudiko/screens/others/infoPage.dart';
import 'package:fudiko/screens/others/infoPage2.dart';
import 'package:fudiko/screens/others/infoPage3.dart';
import 'package:fudiko/screens/others/infoPage4.dart';
import 'package:fudiko/screens/others/menuUpload.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/screens/others/nav/offers/offers.dart';
import 'package:fudiko/screens/others/splashScreen.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/http_overrides.dart';
import 'package:fudiko/utils/translator_service.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
    await TranslatorService.loadSavedLanguage(); // ← load saved language
    SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky, // Hides status bar, shows on swipe then auto-hides
  );
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides(); // ← ADD THIS
  }
  runApp(
    ScreenUtilInit(
      designSize: Size(402, 874),
      minTextAdapt: true,
      builder: (context,child)=> const MyApp(),
    )
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
        colorScheme: ColorScheme.fromSeed(seedColor: appTextColor),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
    );
  }
}
