import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/screens/auth/registration.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/utils/tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    initial();

  }

  Future<void> initial() async{
    final token = await getToken();
    if(token != null){
      Timer(const Duration(seconds: 2), () {
        pushWidgetWhileRemove(newPage: const MainNavPage(), context: context);
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const MainNavPage()),
        // );
      });
    }else{
      Timer(const Duration(seconds: 2), () {
        pushWidgetWhileRemove(newPage: const Login(), context: context);
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const Login()),
        // );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Splashpage.png',
      fit: BoxFit.cover,
    );
  }
}