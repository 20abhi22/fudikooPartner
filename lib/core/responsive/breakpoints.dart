import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 600;
  static const double desktop = 1200;

  const Breakpoints._();

  static bool isMobile(double width) => width < mobile;

  static bool isTablet(double width) => width >= tablet && width < desktop;

  static bool isDesktop(double width) => width >= desktop;

  static double shortestSide(Size size) => math.min(size.width, size.height);

  static bool isMobileDevice(Size size) => shortestSide(size) < mobile;

  static bool isTabletDevice(Size size) =>
      shortestSide(size) >= tablet && size.width < desktop;

  static bool isDesktopDevice(Size size) => size.width >= desktop;

  static bool isWideShortPhone(Size size) =>
      isMobileDevice(size) && size.width >= 500 && size.height <= 760;
}
