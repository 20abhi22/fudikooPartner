import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/utils/tokens.dart';
import 'package:fudiko/widgets/app_shell.dart';

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

  Future<void> initial() async {
    final token = await getToken();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      pushWidgetWhileRemove(
        newPage: token != null ? const AppShell() : const Login(),
        context: context,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.sizeOf(context);
          final useContainedSplash =
              Breakpoints.isWideShortPhone(size) ||
              MediaQuery.orientationOf(context) == Orientation.landscape;

          return SizedBox.expand(
            child: Image.asset(
              'assets/images/Splashpage.png',
              fit: useContainedSplash ? BoxFit.fitWidth : BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
