import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/services/device-token-service.dart';
import 'package:fudiko/utils/tokens.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:fudiko/widgets/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// How long the splash art is shown for.
  static const Duration _minimumSplash = Duration(seconds: 2);

  /// How long the top-up may hold the splash beyond that. Whatever it has not
  /// fetched by then keeps downloading in the background and lands in the
  /// cache for the next launch; the few screens affected translate on demand
  /// in the meantime.
  static const Duration _warmUpBudget = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    initial();
  }

  Future<void> initial() async {
    final token = await getToken();

    // Runs alongside the splash delay rather than after it, so a warm-up that
    // finishes quickly costs nothing. Errors are swallowed and the wait is
    // bounded: a cold cache on a slow connection is hundreds of phrases, and
    // waiting it out would strand the user on the splash screen.
    final warmUp = _warmUpTranslations().catchError((Object _) {});

    await Future.wait([
      Future<void>.delayed(_minimumSplash),
      warmUp.timeout(_warmUpBudget, onTimeout: () {}),
    ]);

    if (!mounted) return;

    if (token != null) {
      // Not awaited: keeps the saved token fresh on every launch without
      // holding up navigation if push-permission/registration is slow.
      unawaited(DeviceTokenService().registerDeviceToken());
    }

    pushWidgetWhileRemove(
      newPage: token != null ? const AppShell() : const Login(),
      context: context,
    );
  }

  /// Tops up any phrases still missing for the saved language before the first
  /// screen renders. Normally a no-op — the language switch already warmed
  /// everything up — but it covers a warm-up that was cut short (offline at
  /// the time) and copy added by an app update, either of which would
  /// otherwise show English and swap after the page opened.
  Future<void> _warmUpTranslations() async {
    if (TranslatorService.pendingPhraseCount() == 0) return;
    await TranslatorService.warmUp(TranslatorService.currentLanguage);
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
